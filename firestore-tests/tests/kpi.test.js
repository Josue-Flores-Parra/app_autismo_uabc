// KPI aggregate validation against the Firestore emulator.
//
// Run via:
//   firebase emulators:exec --only firestore --project demo-appy "npm test"
//
// Seeds the exact acceptance fixtures from §15 (KPI 1-7) using firebase-admin
// (bypasses rules, still subject to index requirements) and runs the real
// aggregate queries from `docs/telemetry-kpi-queries.md`.

// Must be set before firebase-admin Firestore connects (emulators:exec sets it
// too; this makes direct `npm test` invocations work as well).
process.env.FIRESTORE_EMULATOR_HOST ??= 'localhost:8080';

const { before, after, describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp } = require('firebase-admin/app');
const {
  getFirestore,
  Timestamp,
  AggregateField,
} = require('firebase-admin/firestore');
const { session } = require('./fixtures.js');

const PROJECT_ID = 'demo-appy';
const COLLECTION = 'telemetryActivitySessions';

let db;

before(async () => {
  initializeApp({ projectId: PROJECT_ID });
  db = getFirestore();
});

after(async () => {
  await db.terminate();
});

// Fixture day windows: each KPI uses its own day so datasets don't collide.
// Year 2027 keeps fixtures clear of any `new Date()` written by other suites.
const day = (d, h = 12) =>
  Timestamp.fromDate(new Date(Date.UTC(2027, 8, d, h)));
const range = (d) => ({ start: day(d, 0), end: day(d + 1, 0) });

async function seed(overrides) {
  const data = session(overrides);
  await db.collection(COLLECTION).doc(data.sessionId).set(data);
  return data.sessionId;
}

const qIn = (d) =>
  db
    .collection(COLLECTION)
    .where('timing.startedAt', '>=', range(d).start)
    .where('timing.startedAt', '<', range(d).end);

describe('KPI aggregate validation', () => {
  it('KPI 1: average active duration over completed = 2000 ms', async () => {
    await seed({
      timing: { activeDurationMs: 1000, startedAt: day(1, 9) },
      lifecycle: { status: 'completed' },
      outcome: { isCompleted: true, objectiveReached: true, terminalReason: 'objective_completed' },
    });
    await seed({
      timing: { activeDurationMs: 3000, startedAt: day(1, 10) },
      lifecycle: { status: 'completed' },
      outcome: { isCompleted: true, objectiveReached: true, terminalReason: 'objective_completed' },
    });
    await seed({
      timing: { activeDurationMs: 9000, startedAt: day(1, 11) },
      lifecycle: { status: 'abandoned' },
      outcome: { isCompleted: false, terminalReason: 'user_exit' },
    });

    const q = qIn(1).where('lifecycle.status', '==', 'completed');
    const count = (await q.count().get()).data().count;
    const agg = (
      await q
        .aggregate({
          total: AggregateField.sum('timing.activeDurationMs'),
          avg: AggregateField.average('timing.activeDurationMs'),
        })
        .get()
    ).data();

    assert.equal(count, 2, 'denominator excludes abandoned');
    assert.equal(agg.total, 4000);
    assert.equal(agg.avg, 2000);
  });

  it('KPI 2: replay sum / started count = 3/7', async () => {
    await seed({
      activity: { activityType: 'video', activityId: 'm1:l1:video' },
      interaction: { attemptsApplicable: false, attempts: null, runCount: 0 },
      video: { replayCount: 2, objectiveThreshold: 0.9 },
      timing: { startedAt: day(2, 1) },
    });
    await seed({
      activity: { activityType: 'video', activityId: 'm1:l1:video' },
      interaction: { attemptsApplicable: false, attempts: null, runCount: 0 },
      video: { replayCount: 1, objectiveThreshold: 0.9 },
      timing: { startedAt: day(2, 2) },
    });
    for (let i = 0; i < 5; i++) {
      await seed({ timing: { startedAt: day(2, 3 + i) } }); // non-video, replay 0
    }

    const q = qIn(2).where('outcome.hasStarted', '==', true);
    const count = (await q.count().get()).data().count;
    const sum = (await q.aggregate({ total: AggregateField.sum('video.replayCount') }).get()).data().total;

    assert.equal(count, 7);
    assert.equal(sum, 3);
  });

  it('KPI 3: abandon rate = 2/10 (launch_error excluded)', async () => {
    for (let i = 0; i < 8; i++) {
      await seed({ timing: { startedAt: day(3, 1 + i) } });
    }
    await seed({
      lifecycle: { status: 'abandoned' },
      outcome: { isCompleted: false, terminalReason: 'user_exit' },
      timing: { startedAt: day(3, 10) },
    });
    await seed({
      lifecycle: { status: 'abandoned' },
      outcome: { isCompleted: false, terminalReason: 'inactivity_timeout' },
      timing: { startedAt: day(3, 11) },
    });
    await seed({
      lifecycle: { status: 'launch_error' },
      outcome: { hasStarted: false, isCompleted: false, terminalReason: 'navigation_failed' },
      timing: { startedAt: day(3, 12) },
    });

    const abandoned = (await qIn(3).where('lifecycle.status', '==', 'abandoned').count().get()).data().count;
    const started = (await qIn(3).where('outcome.hasStarted', '==', true).count().get()).data().count;

    assert.equal(abandoned, 2);
    assert.equal(started, 10, 'launch_error hasStarted=false excluded from denominator');
  });

  it('KPI 4/5: navigation 4/10, completion 6/10', async () => {
    for (let i = 0; i < 4; i++) {
      await seed({
        lifecycle: { status: 'completed' },
        outcome: { isCompleted: true, objectiveReached: true, terminalReason: 'objective_completed' },
        timing: { startedAt: day(4, 1 + i) },
      });
    }
    for (let i = 0; i < 2; i++) {
      await seed({
        lifecycle: { status: 'completed', wasInterrupted: true, interruptionCount: 1 },
        outcome: { isCompleted: true, objectiveReached: true, terminalReason: 'objective_completed' },
        timing: { startedAt: day(4, 6 + i) },
      });
    }
    for (let i = 0; i < 4; i++) {
      await seed({ timing: { startedAt: day(4, 10 + i) } }); // started, not completed
    }

    const completed = (await qIn(4).where('lifecycle.status', '==', 'completed').count().get()).data().count;
    const nav = (await qIn(4)
      .where('lifecycle.status', '==', 'completed')
      .where('lifecycle.wasInterrupted', '==', false)
      .count()
      .get()).data().count;
    const started = (await qIn(4).where('outcome.hasStarted', '==', true).count().get()).data().count;

    assert.equal(completed, 6, 'interrupted completions still count for completion');
    assert.equal(nav, 4, 'interrupted completions excluded from navigation');
    assert.equal(started, 10);
  });

  it('KPI 6: average attempts = 3 over completed interactives only', async () => {
    await seed({
      interaction: { attemptsApplicable: true, attempts: 5, runCount: 2 },
      lifecycle: { status: 'completed' },
      outcome: { isCompleted: true, objectiveReached: true, terminalReason: 'objective_completed' },
      timing: { startedAt: day(5, 1) },
    });
    await seed({
      activity: { activityType: 'puzzle', activityId: 'm1:l1:puzzle' },
      interaction: { attemptsApplicable: true, attempts: 1, runCount: 1 },
      lifecycle: { status: 'completed' },
      outcome: { isCompleted: true, objectiveReached: true, terminalReason: 'objective_completed' },
      timing: { startedAt: day(5, 2) },
    });
    await seed({
      activity: { activityType: 'video', activityId: 'm1:l1:video' },
      interaction: { attemptsApplicable: false, attempts: null, runCount: 0 },
      video: { replayCount: 0, objectiveThreshold: 0.9 },
      lifecycle: { status: 'completed' },
      outcome: { isCompleted: true, objectiveReached: true, terminalReason: 'objective_completed' },
      timing: { startedAt: day(5, 3) },
    });
    await seed({
      interaction: { attemptsApplicable: true, attempts: 4, runCount: 2 },
      lifecycle: { status: 'failed' },
      outcome: { isCompleted: false, terminalReason: 'attempts_exhausted' },
      timing: { startedAt: day(5, 4) },
    });

    const q = qIn(5)
      .where('lifecycle.status', '==', 'completed')
      .where('interaction.attemptsApplicable', '==', true);
    const count = (await q.count().get()).data().count;
    const agg = (
      await q
        .aggregate({
          total: AggregateField.sum('interaction.attempts'),
          avg: AggregateField.average('interaction.attempts'),
        })
        .get()
    ).data();

    assert.equal(count, 2, 'video and failed interactive excluded');
    assert.equal(agg.total, 6);
    assert.equal(agg.avg, 3);
  });

  it('KPI 7: module progress = 3/5 via modules + users reads', async () => {
    const moduleId = 'mod-7';
    const levelIds = ['l1', 'l2', 'l3', 'l4', 'l5'];
    for (const levelId of levelIds) {
      await db.collection('modules').doc(moduleId).collection('levels').doc(levelId).set({ orden: 1 });
    }
    for (const levelId of ['l1', 'l2', 'l3']) {
      await db
        .collection('users')
        .doc('learner-1')
        .collection('progress')
        .doc(moduleId)
        .collection('levels')
        .doc(levelId)
        .set({ status: 'completed', estrellas: 3 });
    }

    const levels = await db.collection('modules').doc(moduleId).collection('levels').get();
    const progress = await db
      .collection('users')
      .doc('learner-1')
      .collection('progress')
      .doc(moduleId)
      .collection('levels')
      .get();
    const completed = progress.docs.filter(
      (doc) =>
        doc.data().status === 'completed' || (doc.data().estrellas ?? 0) > 0,
    ).length;

    assert.equal(levels.size, 5);
    assert.equal(completed, 3);
    assert.equal(completed / levels.size, 3 / 5);
  });
});