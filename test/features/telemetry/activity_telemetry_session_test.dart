import 'package:flutter_test/flutter_test.dart';
import 'package:appy/features/telemetry/model/activity_telemetry_session.dart';
import 'package:appy/features/telemetry/model/telemetry_enums.dart';

const _client = TelemetryClient(
  platform: 'android',
  appVersion: '1.0.0',
  buildNumber: '4',
  locale: 'es',
);

void main() {
  group('ActivityTelemetrySession.launchRequested', () {
    final session = ActivityTelemetrySession.launchRequested(
      sessionId: '9d8d0f8b-0c1f-4b3a-9e1a-3b2a1c0d4e5f',
      learnerId: 'uid-learner',
      actorId: 'uid-learner',
      activityType: TelemetryActivityType.simpleSelection,
      moduleId: 'm1',
      levelId: 'l1',
      client: _client,
    );

    test('documentId == sessionId', () {
      expect(session.sessionId, isNotEmpty);
      expect(
        session.toMap()['sessionId'],
        '9d8d0f8b-0c1f-4b3a-9e1a-3b2a1c0d4e5f',
      );
    });

    test('identityModel is account_as_learner with learnerId == actorId', () {
      expect(session.subject.identityModel, IdentityModel.accountAsLearner);
      expect(session.subject.learnerId, 'uid-learner');
      expect(session.subject.actorId, 'uid-learner');
    });

    test('parent profile session preserves distinct actor and learner IDs', () {
      final session = ActivityTelemetrySession.launchRequested(
        sessionId: '00000000-0000-4000-8000-000000000001',
        learnerId: 'learner-1',
        actorId: 'parent-1',
        identityModel: IdentityModel.parentAsLearner,
        activityType: TelemetryActivityType.video,
        moduleId: 'm1',
        levelId: 'l1',
        client: const TelemetryClient(
          platform: 'test',
          appVersion: '1',
          buildNumber: '1',
          locale: 'es',
        ),
      );

      final restored = ActivityTelemetrySession.fromMap(
        session.toMap(),
        sessionId: session.sessionId,
      );
      expect(restored?.subject.actorId, 'parent-1');
      expect(restored?.subject.learnerId, 'learner-1');
      expect(restored?.subject.identityModel, IdentityModel.parentAsLearner);
    });

    test('activityId derives from module:level:type', () {
      expect(session.activity.activityId, 'm1:l1:simple_selection');
    });

    test('initial state is launch_requested with hasStarted false', () {
      expect(session.lifecycle.status, SessionState.launchRequested);
      expect(session.outcome.hasStarted, isFalse);
      expect(session.outcome.objectiveReached, isFalse);
      expect(session.outcome.isCompleted, isFalse);
      expect(session.outcome.terminalReason, isNull);
    });

    test('interactive defaults: attempts applicable, runCount 1', () {
      expect(session.interaction.attemptsApplicable, isTrue);
      expect(session.interaction.attempts, 0);
      expect(session.interaction.runCount, 1);
    });

    test(
      'non-interactive defaults: attemptsApplicable false, attempts null',
      () {
        final media = ActivityTelemetrySession.launchRequested(
          sessionId: 'another-uuid',
          learnerId: 'u',
          actorId: 'u',
          activityType: TelemetryActivityType.video,
          moduleId: 'm1',
          levelId: 'l1',
          client: _client,
        );
        expect(media.interaction.attemptsApplicable, isFalse);
        expect(media.interaction.attempts, isNull);
        expect(media.interaction.runCount, 0);
        expect(media.video.objectiveThreshold, 0.9);
      },
    );

    test('no PII nor archive fields in serialization', () {
      final map = session.toMap();
      expect(map.containsKey('archive'), isFalse);
      expect(map.containsKey('archived'), isFalse);
      expect(map.containsKey('archiveAt'), isFalse);
      expect(map.containsKey('name'), isFalse);
      expect(map.containsKey('email'), isFalse);
      expect(map.containsKey('displayName'), isFalse);
    });
  });

  group('copyWith', () {
    test('immutable and returns new instance', () {
      final session = ActivityTelemetrySession.launchRequested(
        sessionId: 'id-1',
        learnerId: 'u',
        actorId: 'u',
        activityType: TelemetryActivityType.puzzle,
        moduleId: 'm',
        levelId: 'l',
        client: _client,
      );
      final updated = session.copyWith(
        outcome: session.outcome.copyWith(hasStarted: true),
      );
      expect(updated.outcome.hasStarted, isTrue);
      expect(session.outcome.hasStarted, isFalse);
      expect(identical(session, updated), isFalse);
    });
  });

  group('round-trip serialization', () {
    test('toMap -> fromMap preserves core semantics', () {
      final original = ActivityTelemetrySession.launchRequested(
        sessionId: 'rt-uuid',
        learnerId: 'learner',
        actorId: 'actor',
        activityType: TelemetryActivityType.puzzle,
        moduleId: 'mod',
        levelId: 'lvl',
        gridSize: 4,
        difficulty: 'normal',
        client: _client,
      );
      final restored = ActivityTelemetrySession.fromMap(
        original.toMap(),
        sessionId: 'rt-uuid',
      );
      expect(restored, isNotNull);
      expect(restored!.activity.gridSize, 4);
      expect(restored.activity.difficulty, 'normal');
      expect(restored.activity.activityType, TelemetryActivityType.puzzle);
      expect(restored.subject.learnerId, 'learner');
      expect(restored.subject.actorId, 'actor');
    });
  });
}
