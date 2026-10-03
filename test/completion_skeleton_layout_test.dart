import 'dart:async';

import 'package:appy/features/learning_module/data/completion_sync_service.dart';
import 'package:appy/features/learning_module/view/level_play_screen.dart';
import 'package:appy/features/minigames/minigame_core.dart';
import 'package:appy/features/minigames/view/minigames_widget.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:appy/shared/services/level_completion_service.dart';
import 'package:appy/shared/widgets/completion_rewards_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CompletionEvent _event() => CompletionEvent(
  id: 'layout',
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

Widget _app(Widget home, {double scale = 1, bool reduceMotion = true}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: home,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final scale in [1.0, 2.3]) {
    for (final video in [false, true]) {
      for (final depleted in [false, true]) {
        testWidgets(
          'dialog remains fixed: video=$video scale=$scale depleted=$depleted',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final confirmed = Completer<CompletionReward?>();
            final queue = CompletionSyncService(
              prefs: await SharedPreferences.getInstance(),
              confirm: (_) => confirmed.future,
              actorProvider: () => 'parent',
            );
            await queue.enqueue(_event());
            final pending = LevelCompletionResult(
              success: true,
              attempts: 0,
              stars: 1,
              coins: 0,
              syncState: CompletionSyncState.pending,
              syncService: queue,
              completionId: 'layout',
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
                            completionRecorder: () async => pending,
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LevelPlayScreen(
                                levelTitle: 'Nivel',
                                actividadType: 'puzzle',
                                completionRecorder: (_, _) async => pending,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                scale: scale,
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
            final shimmer = find.byKey(
              const ValueKey('completion-rewards-shimmer'),
            );
            expect(shimmer, findsOneWidget);
            expect(find.text('Monedas: +30'), findsNothing);
            expect(
              find.text('Recompensas pendientes de sincronización.'),
              findsNothing,
            );
            final dialogRect = tester.getRect(find.byType(AlertDialog));
            final actionRect = tester.getRect(find.text('Continuar'));
            final rewardSize = tester.getSize(
              find.byType(CompletionRewardsSection),
            );
            confirmed.complete(
              CompletionReward(
                stars: 1,
                coins: 30,
                happiness: depleted ? 0 : 5,
                energy: -4,
                noEnergy: depleted,
                replay: false,
              ),
            );
            await queue.flush();
            await tester.pumpAndSettle();
            expect(shimmer, findsNothing);
            expect(find.text('Monedas: +30'), findsOneWidget);
            expect(tester.getRect(find.byType(AlertDialog)), dialogRect);
            expect(tester.getRect(find.text('Continuar')), actionRect);
            expect(
              tester.getSize(find.byType(CompletionRewardsSection)),
              rewardSize,
            );
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('Continuar'));
            await tester.pumpAndSettle();
            await tester.pumpWidget(const SizedBox());
            queue.dispose();
          },
        );
      }
    }
  }

  testWidgets(
    'shimmer animates, stops on confirmation, and honors reduced motion',
    (tester) async {
      Widget panel(bool loading, bool reduceMotion) => _app(
        Scaffold(
          body: CompletionRewardsSection(
            loading: loading,
            loadingLabel: 'Cargando recompensas',
            children: const [Text('Monedas: +30')],
          ),
        ),
        reduceMotion: reduceMotion,
      );
      await tester.pumpWidget(panel(true, false));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(
        find.byKey(const ValueKey('completion-rewards-shimmer')),
        findsOneWidget,
      );
      await tester.pumpWidget(panel(false, false));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(
        find.byKey(const ValueKey('completion-rewards-shimmer')),
        findsNothing,
      );
      await tester.pumpWidget(panel(true, true));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(
        find.byKey(const ValueKey('completion-rewards-shimmer')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
