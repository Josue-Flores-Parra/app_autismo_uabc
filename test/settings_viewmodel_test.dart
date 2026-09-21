import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:appy/shared/services/feedback_preferences.dart';
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

  test('persists parental allowed modules and clamps out of range values', () async {
    final viewModel = SettingsViewModel();
    await waitForPrefs();

    expect(viewModel.parentalAllowedModules, 0);

    viewModel.setParentalAllowedModules(2);
    await waitForPrefs();

    final rehydrated = SettingsViewModel();
    await waitForPrefs();
    expect(rehydrated.parentalAllowedModules, 2);

    rehydrated.setParentalAllowedModules(50);
    expect(rehydrated.parentalAllowedModules, 10);
    rehydrated.setParentalAllowedModules(-3);
    expect(rehydrated.parentalAllowedModules, 0);
  });

  test('mirrors audio and haptic switches into FeedbackPreferences', () async {
    final viewModel = SettingsViewModel();
    await waitForPrefs();

    expect(FeedbackPreferences.audioEnabled, isTrue);

    viewModel.toggleAudioFeedback(false);
    viewModel.toggleHapticFeedback(false);

    expect(FeedbackPreferences.audioEnabled, isFalse);
    expect(FeedbackPreferences.hapticsEnabled, isFalse);

    viewModel.toggleAudioFeedback(true);
    viewModel.toggleHapticFeedback(true);
  });
}

