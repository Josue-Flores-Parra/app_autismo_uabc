// Firestore security rules tests for `telemetryActivitySessions`.
//
// Run via:
//   firebase emulators:exec --only firestore --project demo-appy "npm test"
//
// Covers the §12 matrix: create own/foreign/invalid, immutable fields, terminal
// immutability, counter no-decrement, declared transitions, sticky interruption,
// delete own-only, read own-only, list only filtered by own actorId.

const { before, after, describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { session, deepMerge } = require('./fixtures.js');

const PROJECT_ID = 'demo-appy';
const RULES_PATH = join(__dirname, '..', '..', 'firestore.rules');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(RULES_PATH, 'utf8') },
  });
});

after(async () => {
  await testEnv.cleanup();
});

const owner = () => testEnv.authenticatedContext('uid-1').firestore();
const other = () => testEnv.authenticatedContext('uid-2').firestore();
const ref = (db, id) =>
  db.collection('telemetryActivitySessions').doc(id);

// Session owned by the authenticated 'uid-1' actor (rules require
// subject.actorId == request.auth.uid).
const ownSession = (overrides = {}) =>
  session(
    deepMerge(
      { subject: { learnerId: 'uid-1', actorId: 'uid-1' } },
      overrides,
    ),
  );

describe('telemetryActivitySessions rules', () => {
  describe('create', () => {
    it('allows own valid launch_requested session', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
    });

    it('rejects create with actorId != uid', async () => {
      const data = ownSession({
        subject: { actorId: 'uid-2' },
        lifecycle: { status: 'launch_requested' },
        outcome: { hasStarted: false },
      });
      await assertFails(ref(owner(), data.sessionId).set(data));
    });

    it('rejects create with learnerId != uid under account_as_learner', async () => {
      const data = ownSession({
        subject: { learnerId: 'uid-2' },
        lifecycle: { status: 'launch_requested' },
        outcome: { hasStarted: false },
      });
      await assertFails(ref(owner(), data.sessionId).set(data));
    });

    it('rejects create with non-uuid document id', async () => {
      const data = ownSession({
        sessionId: 'not-a-uuid',
        lifecycle: { status: 'launch_requested' },
        outcome: { hasStarted: false },
      });
      await assertFails(ref(owner(), data.sessionId).set(data));
    });

    it('rejects create whose status is not launch_requested', async () => {
      const data = ownSession({ lifecycle: { status: 'started' }, outcome: { hasStarted: true } });
      await assertFails(ref(owner(), data.sessionId).set(data));
    });

    it('rejects create with an archive field', async () => {
      const data = ownSession({
        archive: true,
        lifecycle: { status: 'launch_requested' },
        outcome: { hasStarted: false },
      });
      await assertFails(ref(owner(), data.sessionId).set(data));
    });

    it('rejects unauthenticated create', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertFails(ref(db, data.sessionId).set(data));
    });
  });

  describe('update and transitions', () => {
    async function createLaunch() {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      return data;
    }

    it('allows launch_requested -> started', async () => {
      const data = await createLaunch();
      await assertSucceeds(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'started',
          'outcome.hasStarted': true,
          'timing.startedAt': new Date('2000-01-01T00:00:00Z'),
          'timing.activeDurationMs': 100,
        }),
      );
    });

    it('allows started -> completed', async () => {
      const data = await createLaunch();
      await assertSucceeds(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'started',
          'outcome.hasStarted': true,
          'timing.startedAt': new Date('2000-01-01T00:00:00Z'),
        }),
      );
      await assertSucceeds(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'completed',
          'outcome.isCompleted': true,
          'outcome.terminalReason': 'objective_completed',
          'timing.terminalAt': new Date(),
        }),
      );
    });

    it('rejects invalid transition launch_requested -> completed', async () => {
      const data = await createLaunch();
      await assertFails(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'completed',
          'outcome.hasStarted': true,
          'outcome.isCompleted': true,
          'outcome.terminalReason': 'objective_completed',
        }),
      );
    });

    it('rejects updates to a terminal session (immutable)', async () => {
      const data = await createLaunch();
      await assertSucceeds(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'started',
          'outcome.hasStarted': true,
          'timing.startedAt': new Date('2000-01-01T00:00:00Z'),
        }),
      );
      await assertSucceeds(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'completed',
          'outcome.isCompleted': true,
          'outcome.terminalReason': 'objective_completed',
        }),
      );
      await assertFails(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'abandoned',
          'outcome.isCompleted': false,
          'outcome.terminalReason': 'user_exit',
        }),
      );
    });

    it('rejects mutating actorId', async () => {
      const data = await createLaunch();
      await assertFails(ref(owner(), data.sessionId).update({ 'subject.actorId': 'uid-2' }));
    });

    it('rejects mutating activity identity', async () => {
      const data = await createLaunch();
      await assertFails(ref(owner(), data.sessionId).update({ 'activity.moduleId': 'm2' }));
    });

    it('rejects decrementing activeDurationMs', async () => {
      const data = await createLaunch();
      await assertSucceeds(
        ref(owner(), data.sessionId).update({
          'lifecycle.status': 'started',
          'outcome.hasStarted': true,
          'timing.startedAt': new Date('2000-01-01T00:00:00Z'),
          'timing.activeDurationMs': 100,
        }),
      );
      await assertFails(ref(owner(), data.sessionId).update({ 'timing.activeDurationMs': 50 }));
    });

    it('rejects decrementing replayCount', async () => {
      const data = await createLaunch();
      await assertSucceeds(ref(owner(), data.sessionId).update({ 'video.replayCount': 2 }));
      await assertFails(ref(owner(), data.sessionId).update({ 'video.replayCount': 1 }));
    });

    it('rejects decrementing runCount', async () => {
      const data = await createLaunch();
      await assertFails(ref(owner(), data.sessionId).update({ 'interaction.runCount': 0 }));
    });

    it('rejects decrementing attempts', async () => {
      const data = await createLaunch();
      await assertSucceeds(ref(owner(), data.sessionId).update({ 'interaction.attempts': 5 }));
      await assertFails(ref(owner(), data.sessionId).update({ 'interaction.attempts': 3 }));
    });

    it('rejects wasInterrupted true -> false (sticky)', async () => {
      const data = await createLaunch();
      await assertSucceeds(ref(owner(), data.sessionId).update({ 'lifecycle.wasInterrupted': true }));
      await assertFails(ref(owner(), data.sessionId).update({ 'lifecycle.wasInterrupted': false }));
    });
  });

  describe('delete, read, list', () => {
    // Account and child-profile deletion remove the owner's telemetry.
    it('allows deleting own document', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertSucceeds(ref(owner(), data.sessionId).delete());
    });

    it('rejects deleting another user document', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertFails(ref(other(), data.sessionId).delete());
    });

    it('allows reading own document', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertSucceeds(ref(owner(), data.sessionId).get());
    });

    it('rejects reading another user document', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertFails(ref(other(), data.sessionId).get());
    });

    it('rejects listing the collection without an actor filter', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertFails(owner().collection('telemetryActivitySessions').get());
    });

    it('allows listing filtered by own actorId', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertSucceeds(
        owner().collection('telemetryActivitySessions')
          .where('subject.actorId', '==', 'uid-1').get(),
      );
    });

    it('allows listing filtered by own actorId and learnerId', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertSucceeds(
        owner().collection('telemetryActivitySessions')
          .where('subject.actorId', '==', 'uid-1')
          .where('subject.learnerId', '==', 'uid-1').get(),
      );
    });

    it('rejects listing filtered by another actorId', async () => {
      const data = ownSession({ lifecycle: { status: 'launch_requested' }, outcome: { hasStarted: false } });
      await assertSucceeds(ref(owner(), data.sessionId).set(data));
      await assertFails(
        other().collection('telemetryActivitySessions')
          .where('subject.actorId', '==', 'uid-1').get(),
      );
    });

    it('rejects listing filtered only by learnerId', async () => {
      await assertFails(
        owner().collection('telemetryActivitySessions')
          .where('subject.learnerId', '==', 'uid-1').get(),
      );
    });
  });

  describe('parent-owned learner profiles', () => {
    async function seedLearner(parentUid, learnerUid) {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection('users').doc(parentUid).set({
          role: 'parent',
          profilesInitialized: true,
        });
        await db.collection('users').doc(parentUid)
          .collection('learners').doc(learnerUid).set({
            name: 'Alex',
            parentUid,
            allowedModules: 0,
            migrationStatus: 'complete',
          });
        await db.collection('users').doc(learnerUid).set({
          role: 'learner',
          parentUid,
          name: 'Alex',
        });
        const profile = await db.collection('users').doc(parentUid)
          .collection('learners').doc(learnerUid).get();
        const learner = await db.collection('users').doc(learnerUid).get();
        assert.equal(profile.data().parentUid, parentUid);
        assert.equal(learner.data().parentUid, parentUid);
      });
    }

    it('allows the owning parent to read the learner user document', async () => {
      await seedLearner('uid-1', 'learner-1');
      const child = owner().collection('users').doc('learner-1');
      await assertSucceeds(child.get());
    });

    it('allows creating a linked profile and learner data document atomically', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('uid-1').set({
          role: 'parent',
          profilesInitialized: true,
        });
      });
      const db = owner();
      const batch = db.batch();
      const profile = db.collection('users').doc('uid-1')
        .collection('learners').doc('learner-new');
      const learner = db.collection('users').doc('learner-new');
      batch.set(profile, {
        name: 'Sam',
        parentUid: 'uid-1',
        allowedModules: 0,
        migrationStatus: 'complete',
      });
      batch.set(learner, {
        role: 'learner',
        parentUid: 'uid-1',
        name: 'Sam',
      });
      await assertSucceeds(batch.commit());
    });

    it('allows the owning parent to update child progress', async () => {
      await seedLearner('uid-1', 'learner-1');
      const child = owner().collection('users').doc('learner-1');
      await assertSucceeds(
        child.collection('progress').doc('module-1')
          .collection('levels').doc('level-1').set({ estrellas: 1 }),
      );
    });

    it('denies a different parent access to a child profile and progress', async () => {
      await seedLearner('uid-1', 'learner-1');
      const child = other().collection('users').doc('learner-1');
      await assertFails(child.get());
      await assertFails(
        child.collection('progress').doc('module-1')
          .collection('levels').doc('level-1').set({ estrellas: 1 }),
      );
    });

    it('allows saving per-child settings and rejects out-of-range values', async () => {
      await seedLearner('uid-1', 'learner-1');
      const profile = owner().collection('users').doc('uid-1')
        .collection('learners').doc('learner-1');
      await assertSucceeds(profile.update({
        settings: {
          fontScale: 'large',
          highContrast: true,
          reduceAnimations: false,
          audioFeedback: true,
          hapticFeedback: true,
          remindersEnabled: false,
          reminderTime: '18:00',
        },
      }));
      await assertFails(profile.update({
        settings: {
          fontScale: 'huge',
          highContrast: true,
          reduceAnimations: false,
          audioFeedback: true,
          hapticFeedback: true,
          remindersEnabled: false,
          reminderTime: '18:00',
        },
      }));
    });

    it('allows the owner to delete child records during parent account cleanup', async () => {
      await seedLearner('uid-1', 'learner-1');
      const db = owner();
      await assertSucceeds(db.collection('users').doc('learner-1').delete());
      await assertSucceeds(
        db.collection('users').doc('uid-1')
          .collection('learners').doc('learner-1').delete(),
      );
    });

    it('supports the repaired migration order for a legacy account', async () => {
      // Legacy account: no role, level progress beneath a missing
      // intermediate progress/{module} document.
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection('users').doc('uid-legacy').set({
          name: 'Old',
          email: 'old@example.com',
          createdAt: '2024-05-01T00:00:00.000Z',
        });
        await db.collection('users').doc('uid-legacy')
          .collection('progress').doc('m1')
          .collection('levels').doc('l1').set({ estrellas: 2 });
      });
      const legacyDb = testEnv.authenticatedContext('uid-legacy').firestore();

      // 1. Claim the parent role without touching existing profile data.
      await assertSucceeds(
        legacyDb.collection('users').doc('uid-legacy').set({ role: 'parent' }, { merge: true }),
      );
      // 2. Create the in-progress profile link.
      await assertSucceeds(
        legacyDb.collection('users').doc('uid-legacy')
          .collection('learners').doc('learner-legacy').set({
            name: 'Old',
            parentUid: 'uid-legacy',
            legacySourceUid: 'uid-legacy',
            allowedModules: 0,
            migrationStatus: 'copying',
            nameConfirmed: false,
          }),
      );
      // 3. Reading the not-yet-created learner doc is denied: the client
      // must create it before reading.
      await assertFails(legacyDb.collection('users').doc('learner-legacy').get());
      // 4. Create-then-read the learner document.
      await assertSucceeds(
        legacyDb.collection('users').doc('learner-legacy').set({
          role: 'learner',
          parentUid: 'uid-legacy',
        }),
      );
      await assertSucceeds(legacyDb.collection('users').doc('learner-legacy').get());
      // 5. Copy level progress discovered without the intermediate document.
      await assertSucceeds(
        legacyDb.collection('users').doc('uid-legacy')
          .collection('progress').doc('m1')
          .collection('levels').doc('l1').get(),
      );
      await assertSucceeds(
        legacyDb.collection('users').doc('learner-legacy')
          .collection('progress').doc('m1')
          .collection('levels').doc('l1').set({ estrellas: 2 }),
      );
      // 6. Finalize the parent account.
      await assertSucceeds(
        legacyDb.collection('users').doc('uid-legacy').set({
          role: 'parent',
          profilesInitialized: true,
          legacyMigrationLearnerId: 'learner-legacy',
        }, { merge: true }),
      );
    });

    it('allows deleting one child profile in dependency order', async () => {
      await seedLearner('uid-1', 'learner-1');
      const db = owner();
      const progress = db.collection('users').doc('learner-1')
        .collection('progress').doc('m1').collection('levels').doc('l1');
      await assertSucceeds(progress.set({ estrellas: 2 }));
      // Progress first: its rules resolve ownership through the learner doc,
      // which must still exist.
      await assertSucceeds(progress.delete());
      await assertSucceeds(
        db.collection('users').doc('uid-1')
          .collection('learners').doc('learner-1').delete(),
      );
      await assertSucceeds(db.collection('users').doc('learner-1').delete());
    });

    it('denies a different parent deleting a child profile', async () => {
      await seedLearner('uid-1', 'learner-1');
      const otherDb = other();
      await assertFails(
        otherDb.collection('users').doc('uid-1')
          .collection('learners').doc('learner-1').delete(),
      );
      await assertFails(otherDb.collection('users').doc('learner-1').delete());
    });

    it('allows valid parent_as_learner telemetry', async () => {
      await seedLearner('uid-1', 'learner-1');
      const linked = ownSession({
        subject: {
          learnerId: 'learner-1',
          actorId: 'uid-1',
          identityModel: 'parent_as_learner',
        },
        lifecycle: { status: 'launch_requested' },
        outcome: { hasStarted: false },
      });
      await assertSucceeds(ref(owner(), linked.sessionId).set(linked));
    });

    it('rejects parent_as_learner telemetry for an unlinked learner', async () => {
      await seedLearner('uid-1', 'learner-1');
      const unlinked = ownSession({
        subject: {
          learnerId: 'foreign-learner',
          actorId: 'uid-1',
          identityModel: 'parent_as_learner',
        },
        lifecycle: { status: 'launch_requested' },
        outcome: { hasStarted: false },
      });
      await assertFails(ref(owner(), unlinked.sessionId).set(unlinked));
    });
  });

  // Parental consent record: only the confirmation function (Admin SDK)
  // may clear the pending flag or record the confirmation email.
  describe('users.legal consent confirmation', () => {
    const userDoc = (db) => db.collection('users').doc('uid-1');
    const accepted = {
      role: 'parent',
      legal: { version: 2, consentMethod: 'email_plus', confirmationPending: true },
    };

    it('allows a parent to record an acceptance pending confirmation', async () => {
      await assertSucceeds(userDoc(owner()).set(accepted));
    });

    it('rejects a parent writing confirmationSentAt', async () => {
      await assertFails(
        userDoc(owner()).set({
          role: 'parent',
          legal: { version: 2, confirmationPending: false, confirmationSentAt: 'now' },
        }),
      );
    });

    it('rejects a parent clearing the pending flag', async () => {
      await assertSucceeds(userDoc(owner()).set(accepted));
      await assertFails(
        userDoc(owner()).set({ legal: { confirmationPending: false } }, { merge: true }),
      );
    });

    it('keeps server-written confirmation fields on unrelated updates', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('uid-1').set({
          role: 'parent',
          legal: {
            version: 2,
            confirmationPending: false,
            confirmationVersion: 2,
            confirmationSentAt: 'server',
          },
        });
      });
      await assertSucceeds(userDoc(owner()).set({ name: 'Ana' }, { merge: true }));
    });

    it('allows re-acceptance of a new version to request a new confirmation', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc('uid-1').set({
          role: 'parent',
          legal: { version: 2, confirmationPending: false, confirmationVersion: 2, confirmationSentAt: 'server' },
        });
      });
      await assertSucceeds(
        userDoc(owner()).set({ legal: { version: 3, confirmationPending: true } }, { merge: true }),
      );
    });
  });
});
