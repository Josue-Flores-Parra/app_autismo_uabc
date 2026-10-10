// Shared helpers for Firestore emulator tests.
//
// This module must NOT depend on firebase-admin nor @firebase/rules-unit-testing
// so it can be reused by both the rules harness and the KPI harness.

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function isPlainObject(v) {
  return v != null && typeof v === 'object' && !Array.isArray(v);
}

// Recursive merge; `overrides` wins. `undefined` values are skipped.
function deepMerge(base, overrides) {
  if (!isPlainObject(base) || !isPlainObject(overrides)) {
    return overrides === undefined ? base : overrides;
  }
  const out = { ...base };
  for (const key of Object.keys(overrides)) {
    if (overrides[key] === undefined) continue;
    out[key] = isPlainObject(out[key])
      ? deepMerge(out[key], overrides[key])
      : overrides[key];
  }
  return out;
}

// Canonical telemetry session document (scheme v1) used by both harnesses.
// The caller provides `timing.startedAt` (a Firestore Timestamp) when relevant.
function session(overrides = {}) {
  const base = {
    schemaVersion: 1,
    sessionId: uuid(),
    subject: {
      learnerId: 'learner-1',
      actorId: 'actor-1',
      identityModel: 'account_as_learner',
    },
    activity: {
      activityId: 'm1:l1:simple_selection',
      moduleId: 'm1',
      levelId: 'l1',
      activityType: 'simple_selection',
    },
    outcome: {
      hasStarted: true,
      objectiveReached: false,
      isCompleted: false,
      navigationSuccessful: false,
      terminalReason: null,
    },
    timing: {
      activeDurationMs: 0,
      activeSegmentCount: 1,
    },
    lifecycle: {
      status: 'started',
      wasInterrupted: false,
      interruptionCount: 0,
    },
    interaction: {
      attemptsApplicable: true,
      attempts: 0,
      runCount: 1,
    },
    video: {
      replayCount: 0,
      objectiveThreshold: null,
    },
    client: {
      platform: 'android',
      appVersion: '1.0.0',
      buildNumber: '4',
      locale: 'es',
    },
  };
  return deepMerge(base, overrides);
}

module.exports = { uuid, session, deepMerge };