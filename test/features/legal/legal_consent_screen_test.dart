import 'package:appy/features/legal/view/legal_consent_screen.dart';
import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta la pantalla de consentimiento con el idioma de la app en [locale].
///
/// La pantalla solo lee `LegalViewModel` y `AuthViewModel` al aceptar o
/// rechazar, así que estas pruebas no necesitan Firebase.
Future<void> pumpConsent(WidgetTester tester, Locale locale) async {
  // Pantalla alta para que la lista construya también la casilla final.
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = SettingsViewModel();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  settings.setLocale(locale);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LegalConsentScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('English parents consent in English', (tester) async {
    await pumpConsent(tester, const Locale('en'));

    expect(find.text('Before you continue'), findsOneWidget);
    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.text('Privacy Notice'), findsOneWidget);
    expect(find.text('Not read'), findsNWidgets(2));
    expect(find.textContaining('I declare that I am of legal age'), findsOne);
    expect(find.text('I accept'), findsOneWidget);
    expect(find.text('I don\'t accept'), findsOneWidget);
    // Ningún texto de la versión en español debe quedar fijo en la pantalla.
    expect(find.text('Antes de continuar'), findsNothing);
    expect(find.text('Acepto'), findsNothing);
    expect(find.textContaining('soy mayor de edad'), findsNothing);
  });

  testWidgets('Spanish parents consent in Spanish', (tester) async {
    await pumpConsent(tester, const Locale('es'));

    expect(find.text('Antes de continuar'), findsOneWidget);
    expect(find.text('Sin leer'), findsNWidgets(2));
    expect(find.textContaining('soy mayor de edad'), findsOneWidget);
    expect(find.text('Acepto'), findsOneWidget);
    expect(find.text('I accept'), findsNothing);
  });

  testWidgets('accepting stays disabled until both documents are read', (
    tester,
  ) async {
    await pumpConsent(tester, const Locale('en'));

    final accept = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(accept.onPressed, isNull);
    expect(
      find.text('Open and read both documents to be able to accept.'),
      findsOneWidget,
    );
  });
}
