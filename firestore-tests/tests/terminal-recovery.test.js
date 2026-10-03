// Verifica la secuencia de recuperación que usa el cliente tras quedar offline.
const { before, after, it } = require('node:test');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { session } = require('./fixtures.js');
let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-appy', firestore: {
    rules: readFileSync(join(__dirname, '..', '..', 'firestore.rules'), 'utf8'),
  }});
});
after(async () => { await env.cleanup(); });

it('recovers pictogram launch through started before abandonment and rejects terminal overwrite', async () => {
  const launch = session({
    subject: { actorId: 'parent', learnerId: 'parent' },
    activity: { activityId: 'm1:l1:pictogram', activityType: 'pictogram' },
    outcome: { hasStarted: false }, lifecycle: { status: 'launch_requested' },
    interaction: { attemptsApplicable: false, attempts: null },
  });
  const ref = env.authenticatedContext('parent').firestore()
    .collection('telemetryActivitySessions').doc(launch.sessionId);
  await assertSucceeds(ref.set(launch));
  const terminal = {
    'lifecycle.status': 'abandoned', 'outcome.hasStarted': true,
    'outcome.isCompleted': false, 'outcome.navigationSuccessful': false,
    'outcome.terminalReason': 'user_exit', 'timing.activeDurationMs': 500,
    'timing.terminalAt': new Date('2026-01-01'),
  };
  await assertFails(ref.update(terminal));
  await assertSucceeds(ref.update({ ...terminal,
    'lifecycle.status': 'started', 'outcome.terminalReason': null,
    'timing.terminalAt': null, 'timing.startedAt': new Date('2026-01-01'),
  }));
  await assertSucceeds(ref.update(terminal));
  await assertFails(ref.update({ 'lifecycle.status': 'started' }));
});

it('completion receipt ownership follows learner progress ownership', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection('users').doc('child').set({ parentUid: 'parent', role: 'learner' });
  });
  const ref = (actor) => env.authenticatedContext(actor).firestore().collection('users').doc('child')
    .collection('progress').doc('_completion_receipts').collection('levels').doc('completion-id');
  await assertSucceeds(ref('parent').set({ completionId: 'completion-id', actorId: 'parent' }));
  await assertSucceeds(ref('parent').get());
  await assertFails(ref('another-parent').get());
  await assertFails(ref('another-parent').set({ completionId: 'completion-id' }));
});
