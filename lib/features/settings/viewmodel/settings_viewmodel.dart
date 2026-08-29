import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontScaleOption { small, medium, large }

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel() {
    _loadPreferences();
  }

  SharedPreferences? _prefs;
  bool _loading = true;

  ThemeMode _themeMode = ThemeMode.system;
  FontScaleOption _fontScale = FontScaleOption.medium;
  Locale _locale = const Locale('es');
  bool _highContrast = false;
  bool _reduceAnimations = false;
  bool _audioFeedback = true;
  bool _hapticFeedback = true;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);
  bool _sendMetrics = false;
  int _parentalMinLevel = 0;

  bool get isReady => !_loading;
  ThemeMode get themeMode => _themeMode;
  FontScaleOption get fontScale => _fontScale;
  Locale get locale => _locale;
  bool get highContrast => _highContrast;
  bool get reduceAnimations => _reduceAnimations;
  bool get audioFeedback => _audioFeedback;
  bool get hapticFeedback => _hapticFeedback;
  bool get remindersEnabled => _remindersEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get sendMetrics => _sendMetrics;
  int get parentalMinLevel => _parentalMinLevel;

  double get textScaleFactor {
    switch (_fontScale) {
      case FontScaleOption.small:
        return 0.9;
      case FontScaleOption.medium:
        return 1.0;
      case FontScaleOption.large:
        return 1.15;
    }
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromString(_prefs?.getString('themeMode'));
    _fontScale = _fontScaleFromString(_prefs?.getString('fontScale'));
    _locale = _localeFromString(_prefs?.getString('locale'));
    _highContrast = _prefs?.getBool('highContrast') ?? false;
    _reduceAnimations = _prefs?.getBool('reduceAnimations') ?? false;
    _audioFeedback = _prefs?.getBool('audioFeedback') ?? true;
    _hapticFeedback = _prefs?.getBool('hapticFeedback') ?? true;
    _remindersEnabled = _prefs?.getBool('remindersEnabled') ?? false;
    _sendMetrics = _prefs?.getBool('sendMetrics') ?? false;
    _parentalMinLevel = _prefs?.getInt('parentalMinLevel') ?? 0;
    _reminderTime =
        _parseStoredTime(_prefs?.getString('reminderTime')) ??
        const TimeOfDay(hour: 18, minute: 0);
    _loading = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString('themeMode', mode.name);
    notifyListeners();
  }

  void setFontScale(FontScaleOption option) {
    _fontScale = option;
    _prefs?.setString('fontScale', option.name);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _prefs?.setString('locale', locale.languageCode);
    notifyListeners();
  }

  void toggleHighContrast(bool value) {
    _highContrast = value;
    _prefs?.setBool('highContrast', value);
    notifyListeners();
  }

  void toggleReduceAnimations(bool value) {
    _reduceAnimations = value;
    _prefs?.setBool('reduceAnimations', value);
    notifyListeners();
  }

  void toggleAudioFeedback(bool value) {
    _audioFeedback = value;
    _prefs?.setBool('audioFeedback', value);
    notifyListeners();
  }

  void toggleHapticFeedback(bool value) {
    _hapticFeedback = value;
    _prefs?.setBool('hapticFeedback', value);
    notifyListeners();
  }

  void toggleReminders(bool value) {
    _remindersEnabled = value;
    _prefs?.setBool('remindersEnabled', value);
    notifyListeners();
  }

  void setReminderTime(TimeOfDay time) {
    _reminderTime = time;
    final timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    _prefs?.setString('reminderTime', timeString);
    notifyListeners();
  }

  void toggleSendMetrics(bool value) {
    _sendMetrics = value;
    _prefs?.setBool('sendMetrics', value);
    notifyListeners();
  }

  void setParentalMinLevel(int level) {
    _parentalMinLevel = level.clamp(0, 10);
    _prefs?.setInt('parentalMinLevel', _parentalMinLevel);
    notifyListeners();
  }

  Future<void> clearCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await _prefs?.reload();
  }

  ThemeMode _themeModeFromString(String? stored) {
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  FontScaleOption _fontScaleFromString(String? stored) {
    switch (stored) {
      case 'small':
        return FontScaleOption.small;
      case 'large':
        return FontScaleOption.large;
      case 'medium':
      default:
        return FontScaleOption.medium;
    }
  }

  Locale _localeFromString(String? stored) {
    if (stored == 'en') return const Locale('en');
    return const Locale('es');
  }

  TimeOfDay? _parseStoredTime(String? stored) {
    if (stored == null) return null;
    final parts = stored.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
