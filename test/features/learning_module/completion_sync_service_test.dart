import 'dart:async';

import 'package:appy/features/learning_module/data/completion_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

CompletionEvent event(
  String id, {
  String actor = 'parent',
  String learner = 'child',
  String activity = 'puzzle',
  bool success = true,
  Map<String, dynamic> baseline = const {},
}) => CompletionEvent(
  id: id,
  actorId: actor,
  learnerId: learner,
  moduleId: 'module',
  levelId: 'level',
  activity: activity,
  success: success,
  attempts: 0,
  firstCoins: 30,
  totalActivities: 3,
  completedAt: DateTime(2026),
  baseline: baseline,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'persists before confirmation and recovers pending progress after restart',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final blocked = Completer<void>();
      final queue = CompletionSyncService(
        prefs: prefs,
        confirm: (_) => blocked.future.then((_) => null),
        actorProvider: () => 'parent',
      );
      await queue.enqueue(event('one'));
      final restored = CompletionSyncService(
        prefs: prefs,
        confirm: (_) async => throw StateError('offline'),
        actorProvider: () => 'parent',
      );
      expect(restored.pending.single.id, 'one');
      expect(restored.overlay('child', 'module', {})['level']!['estrellas'], 1);
      expect(restored.overlay('other-child', 'module', {}), isEmpty);
      blocked.complete();
      await queue.flush();
      queue.dispose();
      restored.dispose();
    },
  );

  test(
    'retains failed events, retries in order and isolates accounts',
    () async {
      final prefs = await SharedPreferences.getInstance();
      var actor = 'other';
      var fail = true;
      final ids = <String>[];
      final queue = CompletionSyncService(
        prefs: prefs,
        actorProvider: () => actor,
        confirm: (e) async {
          if (fail) throw StateError('offline');
          ids.add(e.id);
          return null;
        },
      );
      await queue.enqueue(event('one'));
      await queue.enqueue(event('two', activity: 'video'));
      await queue.flush();
      expect(ids, isEmpty);
      actor = 'parent';
      await queue.flush();
      expect(queue.pending.length, 2);
      fail = false;
      await queue.flush();
      expect(ids, ['one', 'two']);
      expect(queue.pending, isEmpty);
      queue.dispose();
    },
  );

  test('cached Firestore timestamps survive durable storage', () async {
    final prefs = await SharedPreferences.getInstance();
    final queue = CompletionSyncService(
      prefs: prefs,
      confirm: (_) async => throw StateError('offline'),
      actorProvider: () => 'parent',
    );
    await queue.enqueue(
      event(
        'timestamp',
        baseline: {
          'updatedAt': Timestamp.fromDate(DateTime(2026)),
          'activities': {
            'video': {'completedAt': Timestamp.fromDate(DateTime(2026))},
          },
        },
      ),
    );
    await queue.flush();
    final restored = CompletionSyncService(
      prefs: prefs,
      confirm: (_) async => null,
      actorProvider: () => 'parent',
    );
    expect(restored.overlay('child', 'module', {})['level']!['estrellas'], 2);
    queue.dispose();
    restored.dispose();
  });

  test(
    'merges modalities, unlocks levels and preserves legacy completions',
    () {
      var progress = completionProgress({}, event('one'));
      progress = completionProgress(progress, event('two', activity: 'video'));
      progress = completionProgress(
        progress,
        event('three', activity: 'pictogram'),
      );
      expect(progress['estrellas'], 3);
      expect(completionProgress({'estrellas': 3}, event('replay')), {
        'estrellas': 3,
      });
      expect(
        completionProgress({}, event('failed', success: false))['estrellas'],
        0,
      );
    },
  );

  test('preserves reward amounts, replay rules and elapsed rest', () {
    final avatar = {
      'monedas': 7,
      'energia': 80,
      'felicidad': 80,
      'energiaActualizadaEn': DateTime(2026).toIso8601String(),
    };
    final first = completionAvatar(
      avatar,
      {},
      event('one'),
      DateTime(2026, 1, 1, 0, 6),
    );
    expect(first['monedas'], 37);
    expect(first['energia'], 77);
    expect(first['felicidad'], 84);
    final replay = completionAvatar(
      avatar,
      {'estrellas': 3},
      event('two'),
      DateTime(2026),
    );
    expect(replay['monedas'], 12);
    expect(replay['energia'], 83);
    final failed = completionAvatar(
      avatar,
      {},
      event('fail', success: false),
      DateTime(2026),
    );
    expect(failed['monedas'], 7);
    expect(failed['energia'], 76);
  });
}
