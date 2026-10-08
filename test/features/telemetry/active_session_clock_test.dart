import 'package:flutter_test/flutter_test.dart';
import 'package:appy/features/telemetry/service/active_session_clock.dart';

/// Stopwatch controlable para tests deterministas.
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

void main() {
  group('ActiveSessionClock', () {
    test('starts at zero', () {
      final clock = ActiveSessionClock(stopwatch: _FakeStopwatch());
      expect(clock.activeMs, 0);
      expect(clock.segmentCount, 0);
      expect(clock.isRunning, isFalse);
    });

    test('accumulates across multiple segments', () {
      final sw = _FakeStopwatch();
      final clock = ActiveSessionClock(stopwatch: sw);

      clock.startSegment();
      sw.ms = 1000;
      expect(clock.activeMs, 1000);
      clock.stopSegment();
      expect(clock.activeMs, 1000);

      clock.startSegment();
      sw.ms = 250;
      expect(clock.activeMs, 1250);
      clock.stopSegment();
      expect(clock.activeMs, 1250);
      expect(clock.segmentCount, 2);
    });

    test('startSegment is idempotent when already running', () {
      final sw = _FakeStopwatch();
      final clock = ActiveSessionClock(stopwatch: sw);
      clock.startSegment();
      clock.startSegment();
      expect(clock.segmentCount, 1);
    });

    test('stopSegment without running segment is a no-op', () {
      final clock = ActiveSessionClock(stopwatch: _FakeStopwatch());
      expect(clock.stopSegment(), 0);
      expect(clock.activeMs, 0);
    });

    test('background stops time (no accrual while stopped)', () {
      final sw = _FakeStopwatch();
      final clock = ActiveSessionClock(stopwatch: sw);
      clock.startSegment();
      sw.ms = 5000;
      clock.stopSegment();
      // Simular background: sin segmento activo no suma.
      sw.ms = 9999;
      expect(clock.activeMs, 5000);
    });

    test('never returns negative duration', () {
      final sw = _FakeStopwatch();
      final clock = ActiveSessionClock(stopwatch: sw);
      clock.startSegment();
      sw.ms = -5; // Reloj inyectado defectuoso: se recorta a 0 mínimo.
      expect(clock.activeMs, greaterThanOrEqualTo(0));
      clock.stopSegment();
      expect(clock.activeMs, greaterThanOrEqualTo(0));
    });

    test('reset clears accumulator and segments', () {
      final sw = _FakeStopwatch();
      final clock = ActiveSessionClock(stopwatch: sw);
      clock.startSegment();
      sw.ms = 100;
      clock.stopSegment();
      clock.reset();
      expect(clock.activeMs, 0);
      expect(clock.segmentCount, 0);
      expect(clock.isRunning, isFalse);
    });
  });
}