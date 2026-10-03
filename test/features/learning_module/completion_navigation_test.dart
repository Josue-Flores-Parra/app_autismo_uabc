import 'package:appy/features/learning_module/data/completion_sync_service.dart';
import 'package:appy/features/learning_module/view/level_play_screen.dart';
import 'package:appy/features/minigames/minigame_core.dart';
import 'package:appy/features/minigames/view/minigames_widget.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:appy/shared/services/level_completion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final type in ['pictogram', 'puzzle', 'simple_selection']) {
    testWidgets('$type pending completion returns to carousel once', (
      tester,
    ) async {
      var calls = 0;
      for (final game in MinigameType.values) {
        MinigameFactory.register(
          game,
          ({
            required onComplete,
            required minigameData,
            onReady,
            onObjectiveMet,
          }) => const SizedBox(),
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Carousel'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LevelPlayScreen(
                      levelTitle: 'Test',
                      actividadType: type,
                      launchSimpleSelectionFromCard: type == 'simple_selection',
                      minigameData: const {'isSimpleSelectionEnabled': true},
                      completionRecorder: (success, attempts) async {
                        calls++;
                        return LevelCompletionResult(
                          success: true,
                          attempts: 0,
                          stars: 1,
                          coins: 0,
                          syncState: CompletionSyncState.pending,
                        );
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
      await tester.pumpAndSettle();
      final game = tester.widget<MinigamesWidget>(find.byType(MinigamesWidget));
      game.onComplete(true, 0);
      game.onComplete(true, 0);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Rewards pending synchronization.'), findsNothing);
      expect(find.text('Monedas: +0'), findsNothing);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Carousel'), findsOneWidget);
      expect(find.byType(LevelPlayScreen), findsNothing);
    });
  }
  testWidgets('video pending dialog remains dismissible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Finish video'),
              onPressed: () {
                LevelCompletionService.showVideoCompletionDialog(
                  context: context,
                  moduleId: 'module',
                  levelId: 'level',
                  completionRecorder: () async => const LevelCompletionResult(
                    success: true,
                    attempts: 0,
                    stars: 1,
                    coins: 0,
                    syncState: CompletionSyncState.pending,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Finish video'));
    await tester.pumpAndSettle();
    expect(
      find.text('Recompensas pendientes de sincronización.'),
      findsNothing,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('recording error still allows returning to carousel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: LevelPlayScreen(
          levelTitle: 'Test',
          actividadType: 'puzzle',
          completionRecorder: (_, _) async => throw StateError('disk failure'),
        ),
      ),
    );
    tester
        .widget<MinigamesWidget>(find.byType(MinigamesWidget))
        .onComplete(true, 0);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No se pudo guardar el resultado'),
      findsOneWidget,
    );
    expect(find.text('Continuar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
