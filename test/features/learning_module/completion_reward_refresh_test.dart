import 'dart:async';

import 'package:appy/features/learning_module/data/completion_sync_service.dart';
import 'package:appy/features/learning_module/view/level_play_screen.dart';
import 'package:appy/features/minigames/minigame_core.dart';
import 'package:appy/features/minigames/view/minigames_widget.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:appy/shared/services/level_completion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _reward = CompletionReward(
  stars: 1,
  coins: 30,
  happiness: 5,
  energy: -4,
  noEnergy: false,
  replay: false,
);
CompletionEvent _event(String id) => CompletionEvent(
  id: id,
  actorId: 'parent',
  learnerId: 'child',
  moduleId: 'module',
  levelId: 'level',
  activity: 'puzzle',
  success: true,
  attempts: 0,
  firstCoins: 30,
  totalActivities: 3,
  completedAt: DateTime(2026),
);
LevelCompletionResult _result(CompletionSyncService queue, String id) =>
    LevelCompletionResult(
      success: true,
      attempts: 0,
      stars: 1,
      coins: 0,
      syncState: CompletionSyncState.pending,
      completionId: id,
      syncService: queue,
    );
Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('confirmation is scoped to the exact event and actor', () async {
    var actor = 'parent';
    final queue = CompletionSyncService(
      prefs: await SharedPreferences.getInstance(),
      confirm: (_) async => _reward,
      actorProvider: () => actor,
    );
    await queue.enqueue(_event('one'));
    await queue.flush();
    expect(_result(queue, 'one').resolve().coins, 30);
    expect(
      _result(queue, 'one').resolve().syncState,
      CompletionSyncState.confirmed,
    );
    expect(
      _result(queue, 'different').resolve().syncState,
      CompletionSyncState.pending,
    );
    actor = 'other';
    expect(
      _result(queue, 'one').resolve().syncState,
      CompletionSyncState.pending,
    );
    queue.dispose();
  });

  test('drain confirms events added during an existing confirmation', () async {
    final first = Completer<CompletionReward?>();
    final requested = <String>[];
    final queue = CompletionSyncService(
      prefs: await SharedPreferences.getInstance(),
      actorProvider: () => 'parent',
      confirm: (event) {
        requested.add(event.id);
        return event.id == 'one' ? first.future : Future.value(_reward);
      },
    );
    await queue.enqueue(_event('one'));
    await queue.enqueue(_event('two'));
    first.complete(_reward);
    await queue.flush();
    expect(requested, ['one', 'two']);
    expect(queue.pending, isEmpty);
    queue.dispose();
  });

  for (final video in [false, true]) {
    testWidgets(
      '${video ? 'video' : 'minigame'} dialog updates only after server acknowledgement',
      (tester) async {
        final acknowledgement = Completer<CompletionReward?>();
        final prefs = await SharedPreferences.getInstance();
        final queue = CompletionSyncService(
          prefs: prefs,
          confirm: (_) => acknowledgement.future,
          actorProvider: () => 'parent',
        );
        for (final type in MinigameType.values) {
          MinigameFactory.register(
            type,
            ({
              required onComplete,
              required minigameData,
              onReady,
              onObjectiveMet,
            }) => const SizedBox(),
          );
        }
        await queue.enqueue(_event('one'));
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open'),
                  onPressed: () {
                    if (video) {
                      LevelCompletionService.showVideoCompletionDialog(
                        context: context,
                        moduleId: 'module',
                        levelId: 'level',
                        completionRecorder: () async => _result(queue, 'one'),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LevelPlayScreen(
                            levelTitle: 'Nivel',
                            actividadType: 'puzzle',
                            completionRecorder: (_, _) async =>
                                _result(queue, 'one'),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        if (!video) {
          tester
              .widget<MinigamesWidget>(find.byType(MinigamesWidget))
              .onComplete(true, 0);
          await tester.pumpAndSettle();
        }
        expect(
          find.text('Recompensas pendientes de sincronización.'),
          findsOneWidget,
        );
        expect(find.text('Monedas: +30'), findsNothing);
        acknowledgement.complete(_reward);
        await queue.flush();
        await tester.pumpAndSettle();
        expect(
          find.text('Recompensas pendientes de sincronización.'),
          findsNothing,
        );
        expect(find.text('Monedas: +30'), findsOneWidget);
        expect(find.text('+5 felicidad'), findsOneWidget);
        expect(find.text('-4 energía'), findsOneWidget);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        queue.dispose();
      },
    );
  }

  testWidgets('legacy receipt confirms without inventing a reward amount', (
    tester,
  ) async {
    final queue = CompletionSyncService(
      prefs: await SharedPreferences.getInstance(),
      confirm: (_) async => null,
      actorProvider: () => 'parent',
    );
    await queue.enqueue(_event('one'));
    await queue.flush();
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => LevelCompletionService.watchResult(
            _result(queue, 'one'),
            (result) => LevelCompletionService.buildSyncNotice(context, result),
          ),
        ),
      ),
    );
    expect(find.text('Recompensas sincronizadas.'), findsOneWidget);
    expect(_result(queue, 'one').resolve().rewardsKnown, isFalse);
    await tester.pumpWidget(const SizedBox());
    queue.dispose();
  });
}
