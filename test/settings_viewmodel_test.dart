import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> waitForPrefs() => Future.delayed(const Duration(milliseconds: 20));

  test('persists theme mode across instances', () async {
    final viewModel = SettingsViewModel();
    await waitForPrefs();
    viewModel.setThemeMode(ThemeMode.dark);
    await waitForPrefs();

    final rehydrated = SettingsViewModel();
    await waitForPrefs();

    expect(rehydrated.themeMode, ThemeMode.dark);
  });

  test('changes locale and font scale', () async {
    final viewModel = SettingsViewModel();
    await waitForPrefs();

    viewModel.setLocale(const Locale('en'));
    viewModel.setFontScale(FontScaleOption.large);
    await waitForPrefs();

    expect(viewModel.locale.languageCode, 'en');
    expect(viewModel.fontScale, FontScaleOption.large);
    expect(viewModel.textScaleFactor, greaterThan(1));
  });
}

