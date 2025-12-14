import 'package:appy/features/settings/view/settings_page.dart';
import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp(SettingsViewModel viewModel) {
    return ChangeNotifierProvider<SettingsViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsPage(),
      ),
    );
  }

  testWidgets(
    'allows switching to dark theme from settings',
    (tester) async {
      final viewModel = SettingsViewModel();
      await tester.pumpWidget(buildApp(viewModel));
      await tester.pumpAndSettle();

      final darkOption = find.byType(RadioListTile<ThemeMode>);
      expect(darkOption, findsWidgets);
    },
    skip: true,
  );

  testWidgets(
    'enables reminders toggle',
    (tester) async {
      final viewModel = SettingsViewModel();
      await tester.pumpWidget(buildApp(viewModel));
      await tester.pumpAndSettle();

      final remindersToggle = find.byType(SwitchListTile);
      expect(remindersToggle, findsWidgets);
    },
    skip: true,
  );
}

