import 'package:flutter_test/flutter_test.dart';
import 'package:appy/features/telemetry/model/telemetry_enums.dart';

void main() {
  group('SessionState', () {
    test('exposes canonical persisted values', () {
      expect(SessionState.launchRequested.value, 'launch_requested');
      expect(SessionState.started.value, 'started');
      expect(SessionState.completed.value, 'completed');
      expect(SessionState.abandoned.value, 'abandoned');
      expect(SessionState.failed.value, 'failed');
      expect(SessionState.launchError.value, 'launch_error');
    });

    test('fromValue round-trips and rejects unknown values', () {
      for (final state in SessionState.values) {
        expect(SessionState.fromValue(state.value), state);
      }
      expect(SessionState.fromValue('bogus'), isNull);
      expect(SessionState.fromValue(null), isNull);
    });

    test('terminality classification', () {
      expect(SessionState.launchRequested.isTerminal, isFalse);
      expect(SessionState.started.isTerminal, isFalse);
      expect(SessionState.completed.isTerminal, isTrue);
      expect(SessionState.abandoned.isTerminal, isTrue);
      expect(SessionState.failed.isTerminal, isTrue);
      expect(SessionState.launchError.isTerminal, isTrue);
    });

    test('hasStarted flag is true only for started and post-started states', () {
      expect(SessionState.launchRequested.isStarted, isFalse);
      expect(SessionState.launchError.isStarted, isFalse);
      expect(SessionState.started.isStarted, isTrue);
      expect(SessionState.completed.isStarted, isTrue);
      expect(SessionState.abandoned.isStarted, isTrue);
      expect(SessionState.failed.isStarted, isTrue);
    });
  });

  group('TerminalReason', () {
    test('sets are disjoint and exhaustive per terminal state', () {
      expect(
        (TerminalReason.abandonedReasons.toSet()
              ..addAll(TerminalReason.failedReasons)
              ..addAll(TerminalReason.launchErrorReasons)
              ..addAll(TerminalReason.completedReasons))
            .length,
        TerminalReason.values.length,
      );
      // No overlaps.
      final all = <TerminalReason>{};
      for (final set in [
        TerminalReason.abandonedReasons,
        TerminalReason.failedReasons,
        TerminalReason.launchErrorReasons,
        TerminalReason.completedReasons,
      ]) {
        final before = all.length;
        all.addAll(set);
        expect(all.length, before + set.length, reason: 'set overlap detected');
      }
    });

    test('fromValue round-trips', () {
      expect(TerminalReason.fromValue('user_back'),
          TerminalReason.userBack);
      expect(TerminalReason.fromValue('telemetry_opt_out'),
          TerminalReason.telemetryOptOut);
      expect(TerminalReason.fromValue('nope'), isNull);
    });
  });

  group('TelemetryActivityType', () {
    test('normalize lowercases and trims', () {
      expect(TelemetryActivityType.normalize('SIMPLE_SELECTION'),
          TelemetryActivityType.simpleSelection);
      expect(TelemetryActivityType.normalize('  Puzzle '),
          TelemetryActivityType.puzzle);
      expect(TelemetryActivityType.normalize('video'),
          TelemetryActivityType.video);
      expect(TelemetryActivityType.normalize(null), isNull);
      expect(TelemetryActivityType.normalize('nope'), isNull);
    });

    test('attemptsApplicable only for interactive types', () {
      expect(TelemetryActivityType.simpleSelection.attemptsApplicable, isTrue);
      expect(TelemetryActivityType.puzzle.attemptsApplicable, isTrue);
      expect(TelemetryActivityType.video.attemptsApplicable, isFalse);
      expect(TelemetryActivityType.pictogram.attemptsApplicable, isFalse);
      expect(TelemetryActivityType.audio.attemptsApplicable, isFalse);
    });
  });
}