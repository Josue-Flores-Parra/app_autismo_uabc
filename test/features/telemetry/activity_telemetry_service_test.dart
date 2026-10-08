import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appy/features/telemetry/data/telemetry_repository.dart';
import 'package:appy/features/telemetry/model/activity_telemetry_session.dart';
import 'package:appy/features/telemetry/model/telemetry_enums.dart';
import 'package:appy/features/telemetry/model/telemetry_signals.dart';
import 'package:appy/features/telemetry/service/activity_telemetry_service.dart';
import 'package:appy/features/telemetry/service/active_session_clock.dart';
import 'package:appy/features/telemetry/service/pending_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStopwatch extends Stopwatch {
  int ms = 0;
  bool running = false;
  @override
  void start() => running = true;
  @override
  void stop() => running = false;
  @override
  void reset() {
    running = false;
    ms = 0;
  }

  @override
  bool get isRunning => running;
  @override
  int get elapsedMilliseconds => ms;
}

class _FakeRepository extends TelemetryRepository {
  _FakeRepository() : super(null);
  final Map<String, Map<String, dynamic>> docs = {};
  bool failWrites = false;
  int createCalls = 0;

  @override
  Future<void> create(ActivityTelemetrySession session) async {
    createCalls++;
    if (failWrites) throw const TelemetryRepositoryException(
      kind: TelemetryErrorKind.recoverable, operation: 'create');
    docs[session.sessionId] = Map.of(session.toMap());
  }

  Map<String, dynamic> _flatten(Map<String, dynamic> patch) {
    final out = <String, dynamic>{};
    for (final e in patch.entries) {
      final parts = e.key.split('.');
      var cur = out;
      for (var i = 0; i < parts.length - 1; i++) {
        cur = cur.putIfAbsent(parts[i], () => <String, dynamic>{})
            as Map<String, dynamic>;
      }
      cur[parts.last] = e.value;
    }
    return out;
  }

  void _apply(String id, Map<String, dynamic> patch) {
    final existing = docs[id] ?? <String, dynamic>{};
    final merged = _merge(existing, _flatten(patch));
    docs[id] = merged;
  }

  Map<String, dynamic> _merge(Map<String, dynamic> a, Map<String, dynamic> b) {
    final out = Map.of(a);
    b.forEach((k, v) {
      if (v is Map<String, dynamic> && out[k] is Map<String, dynamic>) {
        out[k] = _merge(out[k] as Map<String, dynamic>, v);
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  @override
  Future<void> update(String sessionId, Map<String, dynamic> updates) async {
    if (failWrites) throw const TelemetryRepositoryException(
      kind: TelemetryErrorKind.recoverable, operation: 'update');
    _apply(sessionId, updates);
  }

  @override
  Future<void> updateIfNotTerminal(
      String sessionId, Map<String, dynamic> updates) async {
    if (failWrites) throw const TelemetryRepositoryException(
      kind: TelemetryErrorKind.recoverable, operation: 'updateIfNotTerminal');
    final status = ((docs[sessionId]?['lifecycle'] as Map?) ?? const {})['status'];
    final state = SessionState.fromValue(status as String?);
    if (state != null && state.isTerminal) return; // no overrides terminal.
    _apply(sessionId, updates);
  }

  @override
  Future<ActivityTelemetrySession?> read(String sessionId) async {
    final data = docs[sessionId];
    if (data == null) return null;
    return ActivityTelemetrySession.fromMap(data, sessionId: sessionId);
  }
}

const _client = TelemetryClient(
  platform: 'android',
  appVersion: '1.0.0',
  buildNumber: '4',
  locale: 'es',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repo;
  late SharedPreferences prefs;
  late PendingSessionStore store;
  late String? uid;
  late DateTime now;
  late _FakeStopwatch stopwatch;
  late ActivityTelemetryService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _FakeRepository();
    store = PendingSessionStore(prefs);
    uid = 'uid-1';
    now = DateTime(2026, 1, 1, 10, 0, 0);
    stopwatch = _FakeStopwatch();
    service = ActivityTelemetryService(
      repository: repo,
      pendingStore: store,
      uidProvider: () => uid,
      clockFactory: () => ActiveSessionClock(stopwatch: stopwatch),
      now: () => now,
    );
    await service.updateConsent(ready: true, enabled: true);
  });

  tearDown(() => service.dispose());

  ActivitySessionHandle? launch({TelemetryActivityType type = TelemetryActivityType.simpleSelection}) {
    return service.requestLaunch(
      moduleId: 'm1',
      levelId: 'l1',
      activityType: type,
      client: _client,
    );
  }

  group('consent', () {
    test('no session without ready settings', () async {
      await service.updateConsent(ready: false, enabled: true);
      expect(launch(), isNull);
      expect(repo.createCalls, 0);
    });

    test('no session when disabled', () async {
      await service.updateConsent(ready: true, enabled: false);
      expect(launch(), isNull);
      expect(repo.createCalls, 0);
    });

    test('no session without uid', () async {
      uid = null;
      expect(launch(), isNull);
    });

    test('launch creates a single document with uuid v4 id', () async {
      final handle = launch();
      expect(handle, isNotNull);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.docs.length, 1);
      expect(repo.createCalls, 1);
      final doc = repo.docs[handle!.sessionId]!;
      expect(doc['schemaVersion'], 1);
      expect(doc['sessionId'], handle.sessionId);
      expect(doc['lifecycle']['status'], 'launch_requested');
      expect(doc['outcome']['hasStarted'], isFalse);
    });
  });

  group('state machine', () {
    test('activityReady marks started and starts clock', () async {
      final handle = launch()!;
      stopwatch.ms = 0;
      handle.onActivityReady();
      expect(service.activeSessionCount, 1);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'started');
      expect(doc['outcome']['hasStarted'], isTrue);
      expect(doc['timing']['startedAt'], isNotNull);
      expect(doc['timing']['activeSegmentCount'], 1);
    });

    test('interactive success terminalizes completed with objective', () async {
      final handle = launch()!;
      handle.onActivityReady();
      stopwatch.ms = 1000;
      handle.onObjectiveMet();
      handle.onRecordAttempts(2);
      handle.onComplete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'completed');
      expect(doc['outcome']['isCompleted'], isTrue);
      expect(doc['outcome']['objectiveReached'], isTrue);
      expect(doc['outcome']['terminalReason'], 'objective_completed');
      expect(doc['timing']['terminalAt'], isNotNull);
      expect(doc['interaction']['attempts'], 2);
      expect(service.activeSessionCount, 0);
    });

    test('terminal is immutable: complete after completed is a no-op', () async {
      final handle = launch()!;
      handle.onActivityReady();
      handle.onObjectiveMet();
      handle.onRecordAttempts(1);
      handle.onComplete();
      await Future<void>.delayed(Duration.zero);
      final before = repo.docs[handle.sessionId]!['lifecycle']['status'];
      expect(before, 'completed');

      handle.onAbandon(TerminalReason.userBack);
      handle.onFail();
      await Future<void>.delayed(Duration.zero);
      expect(repo.docs[handle.sessionId]!['lifecycle']['status'], 'completed');
    });

    test('interactive failure with no retries terminalizes failed', () async {
      final handle = launch()!;
      handle.onActivityReady();
      handle.onRecordAttempts(3);
      handle.onFail();
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'failed');
      expect(doc['outcome']['terminalReason'], 'attempts_exhausted');
    });

    test('abandon after started', () async {
      final handle = launch()!;
      handle.onActivityReady();
      handle.onAbandon(TerminalReason.userExit);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'abandoned');
      expect(doc['outcome']['terminalReason'], 'user_exit');
    });

    test('abandon before started is a no-op (stays launch_requested)', () async {
      final handle = launch()!;
      handle.onAbandon(TerminalReason.userBack);
      await Future<void>.delayed(Duration.zero);
      expect(repo.docs[handle.sessionId]!['lifecycle']['status'],
          'launch_requested');
    });

    test('launch_error for pre-started failure', () async {
      final handle = launch()!;
      handle.onLaunchError(TerminalReason.navigationFailed);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'launch_error');
      expect(doc['outcome']['hasStarted'], isFalse);
      expect(doc['outcome']['terminalReason'], 'navigation_failed');
    });
  });

  group('video metrics', () {
    test('replayCount increments only on explicit replay', () async {
      final handle = launch(type: TelemetryActivityType.video)!;
      handle.onActivityReady();
      handle.onRecordVideoReplay();
      handle.onRecordVideoReplay();
      await Future<void>.delayed(Duration.zero);
      expect(repo.docs[handle.sessionId]!['video']['replayCount'], 2);
    });

    test('objective at 90% does not terminalize video; COMPLETAR does', () async {
      final handle = launch(type: TelemetryActivityType.video)!;
      handle.onActivityReady();
      handle.onObjectiveMet();
      await Future<void>.delayed(Duration.zero);
      var doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'started');
      expect(doc['outcome']['objectiveReached'], isTrue);

      handle.onComplete();
      await Future<void>.delayed(Duration.zero);
      doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'completed');
    });
  });

  group('lifecycle', () {
    test('background stops clock and marks a single interruption', () async {
      final handle = launch()!;
      handle.onActivityReady();
      stopwatch.ms = 5000;
      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['wasInterrupted'], isTrue);
      expect(doc['lifecycle']['interruptionCount'], 1);
      // inactive + paused deduplicados a una sola interrupción.
    });

    test('resume within window continues same session', () async {
      final handle = launch()!;
      handle.onActivityReady();
      stopwatch.ms = 1000;
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'started');
      expect(doc['lifecycle']['interruptionCount'], 1);
    });

    test('resume after 15 min abandons with inactivity_timeout', () async {
      final handle = launch()!;
      handle.onActivityReady();
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 15));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'abandoned');
      expect(doc['outcome']['terminalReason'], 'inactivity_timeout');
      expect(service.activeSessionCount, 0);
    });
  });

  group('opt-out', () {
    test('disabling abandons active session with telemetry_opt_out once', () async {
      final handle = launch()!;
      handle.onActivityReady();
      stopwatch.ms = 2000;
      await service.updateConsent(ready: true, enabled: false);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final doc = repo.docs[handle.sessionId]!;
      expect(doc['lifecycle']['status'], 'abandoned');
      expect(doc['outcome']['terminalReason'], 'telemetry_opt_out');
      expect(service.activeSessionCount, 0);
    });
  });
}