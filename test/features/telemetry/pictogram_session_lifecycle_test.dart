import 'package:appy/features/learning_module/view/level_play_screen.dart';
import 'package:appy/features/minigames/view/types/pictogram_minigame.dart';
import 'package:appy/features/telemetry/data/telemetry_repository.dart';
import 'package:appy/features/telemetry/model/activity_telemetry_session.dart';
import 'package:appy/features/telemetry/model/telemetry_enums.dart';
import 'package:appy/features/telemetry/model/telemetry_signals.dart';
import 'package:appy/features/telemetry/service/activity_telemetry_service.dart';
import 'package:appy/features/telemetry/service/pending_session_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends TelemetryRepository {
  _Repository() : super(null);
  final docs = <String, Map<String, dynamic>>{};
  bool fail = false;
  void check() {
    if (fail) {
      throw const TelemetryRepositoryException(
        kind: TelemetryErrorKind.recoverable,
        operation: 'offline',
      );
    }
  }

  @override
  Future<void> create(ActivityTelemetrySession session) async {
    check();
    docs.putIfAbsent(session.sessionId, session.toMap);
  }

  @override
  Future<void> update(String sessionId, Map<String, dynamic> patch) async {
    check();
    final data = docs[sessionId]!;
    for (final entry in patch.entries) {
      final parts = entry.key.split('.');
      var current = data;
      for (final part in parts.take(parts.length - 1)) {
        current = current[part] as Map<String, dynamic>;
      }
      current[parts.last] = entry.value is ServerTimestamp
          ? Timestamp.fromDate(DateTime(2026))
          : entry.value;
    }
  }

  @override
  Future<void> updateIfNotTerminal(
    String sessionId,
    Map<String, dynamic> patch,
  ) async {
    check();
    if (SessionState.fromValue(
      (docs[sessionId]!['lifecycle'] as Map)['status'] as String,
    )!.isTerminal) {
      return;
    }
    await update(sessionId, patch);
  }

  @override
  Future<ActivityTelemetrySession?> read(String sessionId) async {
    check();
    return ActivityTelemetrySession.fromMap(
      docs[sessionId],
      sessionId: sessionId,
    );
  }
}

const _client = TelemetryClient(
  platform: 'android',
  appVersion: '1',
  buildNumber: '1',
  locale: 'es',
);
Future<void> drain() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late PendingSessionStore store;
  late _Repository repository;
  late ActivityTelemetryService service;
  var actor = 'parent';
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = PendingSessionStore(prefs);
    repository = _Repository();
    actor = 'parent';
    service = ActivityTelemetryService(
      repository: repository,
      pendingStore: store,
      uidProvider: () => actor,
    );
    await service.updateConsent(ready: true, enabled: true);
  });
  tearDown(() => service.dispose());
  ActivitySessionHandle launch({
    TelemetryActivityType type = TelemetryActivityType.pictogram,
  }) => service.requestLaunch(
    moduleId: 'module',
    levelId: 'level',
    activityType: type,
    learnerId: 'child',
    client: _client,
  )!;

  test('new launch closes old session and preserves newest marker', () async {
    final old = launch();
    old.onActivityReady();
    await drain();
    final next = launch(type: TelemetryActivityType.puzzle);
    next.onActivityReady();
    await drain();
    expect(repository.docs[old.sessionId]!['lifecycle']['status'], 'abandoned');
    expect(
      repository.docs[old.sessionId]!['outcome']['terminalReason'],
      'route_removed',
    );
    expect(store.read(actor)!.sessionId, next.sessionId);
    expect(service.activeSessionCount, 1);
  });
  test(
    'terminal delivery survives offline failure and service restart',
    () async {
      final handle = launch();
      handle.onActivityReady();
      await drain();
      repository.fail = true;
      handle.onAbandon(TerminalReason.userExit);
      await drain();
      expect(
        store.terminals(actor).single.patch['lifecycle.status'],
        'abandoned',
      );
      service.dispose();
      service = ActivityTelemetryService(
        repository: repository,
        pendingStore: PendingSessionStore(prefs),
        uidProvider: () => actor,
      );
      repository.fail = false;
      await service.updateConsent(ready: true, enabled: true);
      await service.retryPendingTerminals();
      expect(
        repository.docs[handle.sessionId]!['lifecycle']['status'],
        'abandoned',
      );
      expect(store.terminals(actor), isEmpty);
    },
  );
  test(
    'cold offline launch recovers required started transition before terminal',
    () async {
      repository.fail = true;
      final handle = launch();
      handle.onActivityReady();
      handle.onObjectiveMet();
      handle.onComplete();
      await drain();
      expect(store.terminals(actor), hasLength(1));
      repository.fail = false;
      await service.retryPendingTerminals();
      expect(
        repository.docs[handle.sessionId]!['lifecycle']['status'],
        'completed',
      );
      expect(
        repository.docs[handle.sessionId]!['outcome']['hasStarted'],
        isTrue,
      );
      expect(store.terminals(actor), isEmpty);
    },
  );
  test(
    'another account cannot deliver pending telemetry and opt-out discards it',
    () async {
      final handle = launch();
      handle.onActivityReady();
      await drain();
      repository.fail = true;
      handle.onAbandon(TerminalReason.userExit);
      await drain();
      repository.fail = false;
      actor = 'another';
      await service.retryPendingTerminals();
      expect(store.terminals('parent'), hasLength(1));
      actor = 'parent';
      await service.updateConsent(ready: true, enabled: false);
      expect(store.terminals(actor), isEmpty);
      expect(
        repository.docs[handle.sessionId]!['lifecycle']['status'],
        'started',
      );
    },
  );
  test(
    'exit before readiness is launch cancellation and completed remains terminal',
    () async {
      final before = launch();
      before.onLaunchError(TerminalReason.launchCancelledBeforeNavigation);
      await drain();
      expect(
        repository.docs[before.sessionId]!['lifecycle']['status'],
        'launch_error',
      );
      final completed = launch();
      completed.onActivityReady();
      completed.onObjectiveMet();
      completed.onComplete();
      completed.onAbandon(TerminalReason.routeRemoved);
      await drain();
      expect(
        repository.docs[completed.sessionId]!['lifecycle']['status'],
        'completed',
      );
    },
  );
  testWidgets(
    'pictogram close button reports user exit before route disposal',
    (tester) async {
      registerPictogramMinigame();
      final handle = launch();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Carousel'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LevelPlayScreen(
                      levelTitle: 'Test',
                      actividadType: 'pictogram',
                      telemetryHandle: handle,
                      minigameData: const {
                        'steps': ['assets/images/DORMIR.jpg'],
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Carousel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        await drain();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.runAsync(drain);
      expect(find.text('Carousel'), findsOneWidget);
      expect(
        repository.docs[handle.sessionId]!['lifecycle']['status'],
        'abandoned',
      );
      expect(
        repository.docs[handle.sessionId]!['outcome']['terminalReason'],
        'user_exit',
      );
    },
  );
}
