import 'package:appy/core/app_theme.dart';
import 'package:appy/features/authentication/view/login_screen.dart';
import 'package:appy/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:appy/features/learning_module/data/completion_sync_service.dart';
import 'package:appy/features/learning_module/view/level_play_screen.dart';
import 'package:appy/features/minigames/minigame_core.dart';
import 'package:appy/features/minigames/view/minigames_widget.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:appy/shared/services/level_completion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Auth extends ChangeNotifier implements AuthViewModel {
  @override
  bool get isLoading => false;
  @override
  bool get registrationSuccess => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(double scale, Widget home) => MaterialApp(
  theme: AppTheme.light(fontScale: 1, highContrast: false, reduceMotion: true),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: home,
);

void _smallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final scale in [1.0, 1.5, 2.0, 2.3, 3.0]) {
    testWidgets('login registration action remains visible at scale $scale', (
      tester,
    ) async {
      _smallScreen(tester);
      final auth = _Auth();
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: auth,
          child: _app(scale, const LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Regístrate'));
      await tester.pumpAndSettle();
      expect(find.text('Regístrate').hitTestable(), findsOneWidget);
      expect(find.text('¿No tienes una cuenta?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    });

    for (final state in CompletionSyncState.values) {
      for (final success in [true, false]) {
        testWidgets(
          'completion $state success=$success wraps at scale $scale',
          (tester) async {
            _smallScreen(tester);
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
                scale,
                Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      child: const Text('Carousel'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LevelPlayScreen(
                            levelTitle: 'Nivel',
                            actividadType: 'puzzle',
                            completionRecorder: (_, _) async =>
                                LevelCompletionResult(
                                  success: success,
                                  attempts: 123,
                                  stars: 1,
                                  coins: 12345,
                                  syncState: state,
                                  felicidadDelta: 5,
                                  energiaDelta: -4,
                                  sinEnergia: true,
                                ),
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
            tester
                .widget<MinigamesWidget>(find.byType(MinigamesWidget))
                .onComplete(success, 123);
            await tester.pumpAndSettle();
            expect(find.text('Intentos usados: 123'), findsOneWidget);
            if (success && state == CompletionSyncState.confirmed) {
              expect(find.text('Monedas: +12345'), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            final action = find.text(success ? 'Continuar' : 'Volver');
            await tester.ensureVisible(action);
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(find.byType(LevelPlayScreen), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('video rewards wrap and dialog closes at scale $scale', (
      tester,
    ) async {
      _smallScreen(tester);
      await tester.pumpWidget(
        _app(
          scale,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Finish'),
                onPressed: () =>
                    LevelCompletionService.showVideoCompletionDialog(
                      context: context,
                      moduleId: 'module',
                      levelId: 'level',
                      completionRecorder: () async =>
                          const LevelCompletionResult(
                            success: true,
                            attempts: 0,
                            stars: 1,
                            coins: 12345,
                            felicidadDelta: 5,
                            energiaDelta: -4,
                            sinEnergia: true,
                          ),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
