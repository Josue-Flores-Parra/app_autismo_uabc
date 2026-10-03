import 'package:appy/core/app_theme.dart';
import 'package:appy/core/preference_text_scaler.dart';
import 'package:appy/features/onboarding/view/onboarding_screen.dart';
import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:appy/shared/services/settings_access_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize + fontSize * fontSize / 100;
  @override
  double get textScaleFactor => scale(14) / 14;
}

Widget app(double scale, Widget home) => MaterialApp(
  theme: AppTheme.light(fontScale: 1, highContrast: false, reduceMotion: true),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

void smallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({'reduceAnimations': true}),
  );
  test(
    'system scaling and app preference compose without losing nonlinear scaling',
    () {
      const linear = PreferenceTextScaler(TextScaler.linear(1.5), 1.15);
      expect(linear.scale(20), closeTo(34.5, 0.001));
      const nonlinear = PreferenceTextScaler(_NonlinearScaler(), 1.15);
      expect(nonlinear.scale(10), closeTo(12.65, 0.001));
      expect(nonlinear.scale(30), closeTo(44.85, 0.001));
    },
  );

  for (final scale in [1.0, 1.3, 1.5, 2.0, 2.3]) {
    testWidgets('all onboarding pages stay usable at text scale $scale', (
      tester,
    ) async {
      smallScreen(tester);
      final settings = SettingsViewModel();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      var finished = false;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: app(
            scale,
            OnboardingScreen(onFinished: () => finished = true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var page = 0; page < 4; page++) {
        expect(
          tester.takeException(),
          isNull,
          reason: 'Onboarding page $page at scale $scale',
        );
        final button = find.text(page == 3 ? '¡Empezar!' : 'Siguiente');
        expect(button, findsOneWidget);
        final richText = tester
            .widgetList<RichText>(find.byType(RichText))
            .where(
              (text) =>
                  text.text.toPlainText().contains('Te acompaño a aprender'),
            );
        if (page == 0) expect(richText.single.textScaler.scale(16), 16 * scale);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    });

    testWidgets('PIN creation and confirmation fit at text scale $scale', (
      tester,
    ) async {
      smallScreen(tester);
      String? result;
      await tester.pumpWidget(
        app(
          scale,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const SettingsPinDialog(),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // La secuencia rechazada hace visible el mensaje más largo del formulario.
      for (final digit in ['1', '2', '3', '4']) {
        await tester.ensureVisible(find.text(digit));
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('No uses secuencias'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (var run = 0; run < 2; run++) {
        for (final digit in ['5', '8', '2', '6']) {
          await tester.ensureVisible(find.text(digit));
          await tester.tap(find.text(digit));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      }
      expect(result, '5826');
    });

    testWidgets(
      'PIN entry, error and recovery action fit at text scale $scale',
      (tester) async {
        smallScreen(tester);
        await tester.pumpWidget(
          app(
            scale,
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open'),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => const SettingsPinDialog(storedPin: '5678'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        for (final digit in ['1', '2', '3', '4']) {
          await tester.ensureVisible(find.text(digit));
          await tester.tap(find.text(digit));
          await tester.pumpAndSettle();
        }
        expect(find.text('PIN incorrecto'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Olvidé el PIN'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('password recovery scrolls above keyboard at text scale $scale', (
      tester,
    ) async {
      smallScreen(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      String? result;
      await tester.pumpWidget(
        app(
          scale,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const AccountPasswordDialog(
                      email: 'test@example.com',
                      body:
                          'Confirma la contraseña de la cuenta para recuperar el PIN.',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'synthetic-test-password');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(result, 'synthetic-test-password');
    });
  }
}
