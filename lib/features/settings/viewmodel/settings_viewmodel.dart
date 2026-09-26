import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/services/feedback_preferences.dart';
import '../../profiles/model/learner_profile.dart';

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
  // Compatibility surface for older preference clients/tests. New UI reads
  // and writes each learner's Firestore `allowedModules` field instead.
  int _legacyParentalAllowedModules = 0;

  // Consentimiento de telemetría: es por cuenta (UID), no del dispositivo.
  // Así la decisión de una cuenta no afecta a otra ni queda bloqueada para
  // siempre.
  String? _currentUid;
  bool _sendMetrics = false;
  bool _telemetryOnboardingShown = false;

  bool get isReady => !_loading;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Effective per-child preferences. When a learner is selected these come
  /// from its Firestore profile; otherwise the parent device defaults apply.
  LearnerSettings? _activeChild;
  FontScaleOption get fontScale =>
      _fontScaleFromString(_activeChild?.fontScale ?? _fontScale.name);
  bool get highContrast => _activeChild?.highContrast ?? _highContrast;
  bool get reduceAnimations =>
      _activeChild?.reduceAnimations ?? _reduceAnimations;
  bool get audioFeedback => _activeChild?.audioFeedback ?? _audioFeedback;
  bool get hapticFeedback => _activeChild?.hapticFeedback ?? _hapticFeedback;
  bool get remindersEnabled =>
      _activeChild?.remindersEnabled ?? _remindersEnabled;
  TimeOfDay get reminderTime =>
      _parseStoredTime(_activeChild?.reminderTime) ?? _reminderTime;
  bool get sendMetrics => _sendMetrics;

  /// Applies the selected learner's preferences as the effective display and
  /// feedback configuration. Parent-wide choices (theme, language) are
  /// untouched. Called from the provider layer when the profile changes.
  void applyLearnerSettings(LearnerSettings? settings) {
    if (_activeChild == settings) return;
    _activeChild = settings;
    FeedbackPreferences.setAudioEnabled(audioFeedback);
    FeedbackPreferences.setHapticsEnabled(hapticFeedback);
    notifyListeners();
  }

  @Deprecated('Use the selected learner profile allowedModules setting.')
  int get parentalAllowedModules => _legacyParentalAllowedModules;

  /// `true` si ya se mostró el diálogo de consentimiento de telemetría para la
  /// cuenta actual (se muestra una sola vez por cuenta, tras crearla).
  bool get telemetryOnboardingShown => _telemetryOnboardingShown;

  double get textScaleFactor {
    switch (fontScale) {
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
    _legacyParentalAllowedModules =
        _prefs?.getInt('parentalAllowedModules') ?? 0;
    _reminderTime =
        _parseStoredTime(_prefs?.getString('reminderTime')) ??
        const TimeOfDay(hour: 18, minute: 0);
    FeedbackPreferences.setAudioEnabled(_audioFeedback);
    FeedbackPreferences.setHapticsEnabled(_hapticFeedback);
    _loading = false;
    // Aplicar el consentimiento de la cuenta activa (si ya se conoce) una vez
    // que las preferencias están listas.
    _loadTelemetryConsent();
  }

  /// Establece la cuenta activa y carga su consentimiento de telemetría.
  ///
  /// Se invoca desde el Provider al cambiar el usuario de Auth. Las
  /// preferencias parent-wide (tema, idioma) se sincronizan con el documento
  /// `users/{uid}` para que sigan a la cuenta entre dispositivos.
  void setAccount(String? uid) {
    if (_currentUid == uid) return;
    _currentUid = uid;
    _loadTelemetryConsent();
    if (uid != null) {
      _syncParentSettingsFromFirestore(uid);
    }
  }

  Future<void> _syncParentSettingsFromFirestore(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = snapshot.data();
      if (data == null) {
        await _pushParentSettingsToFirestore(uid);
        return;
      }
      final raw = data['parentSettings'];
      final settings = raw is Map<String, dynamic>
          ? raw
          : raw is Map
          ? Map<String, dynamic>.from(raw)
          : null;
      if (settings == null) {
        await _pushParentSettingsToFirestore(uid);
        return;
      }
      var changed = false;
      final remoteTheme = settings['themeMode'];
      if (remoteTheme is String) {
        final parsed = _themeModeFromString(remoteTheme);
        if (parsed != _themeMode) {
          _themeMode = parsed;
          await _prefs?.setString('themeMode', parsed.name);
          changed = true;
        }
      }
      final remoteLocale = settings['locale'];
      if (remoteLocale == 'en' || remoteLocale == 'es') {
        final parsed = Locale(remoteLocale as String);
        if (parsed != _locale) {
          _locale = parsed;
          await _prefs?.setString('locale', parsed.languageCode);
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (_) {
      // Sin lectura confiable se conserva la caché local del dispositivo.
    }
  }

  Future<void> _pushParentSettingsToFirestore(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'parentSettings': {
          'themeMode': _themeMode.name,
          'locale': _locale.languageCode,
        },
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort: la caché local sigue siendo válida.
    }
  }

  void _loadTelemetryConsent() {
    final uid = _currentUid;
    if (uid == null) {
      // Sin cuenta autenticada no hay consentimiento efectivo.
      _sendMetrics = false;
      _telemetryOnboardingShown = false;
    } else {
      _sendMetrics = _prefs?.getBool('sendMetrics_$uid') ?? false;
      _telemetryOnboardingShown =
          _prefs?.getBool('telemetryOnboardingShown_$uid') ?? false;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString('themeMode', mode.name);
    final uid = _currentUid;
    if (uid != null) {
      _pushParentSettingsToFirestore(uid);
    }
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
    final uid = _currentUid;
    if (uid != null) {
      _pushParentSettingsToFirestore(uid);
    }
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
    FeedbackPreferences.setAudioEnabled(value);
    notifyListeners();
  }

  void toggleHapticFeedback(bool value) {
    _hapticFeedback = value;
    _prefs?.setBool('hapticFeedback', value);
    FeedbackPreferences.setHapticsEnabled(value);
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
    final uid = _currentUid;
    if (uid != null) {
      _prefs?.setBool('sendMetrics_$uid', value);
    }
    notifyListeners();
  }

  /// Registra la decisión del diálogo inicial de telemetría para la cuenta
  /// recién creada ([uid]).
  ///
  /// [accepted] `true` habilita `sendMetrics`; `false` lo desactiva. No hay
  /// bloqueo permanente: el usuario puede reactivarlo luego desde Ajustes.
  Future<void> completeTelemetryOnboarding({
    required bool accepted,
    String? uid,
  }) async {
    final targetUid = uid ?? _currentUid;
    _telemetryOnboardingShown = true;
    _sendMetrics = accepted;
    if (targetUid != null) {
      await _prefs?.setBool('telemetryOnboardingShown_$targetUid', true);
      await _prefs?.setBool('sendMetrics_$targetUid', accepted);
    }
    notifyListeners();
  }

  @Deprecated('Use ProfileViewModel.setLearnerAllowedModules.')
  void setParentalAllowedModules(int count) {
    _legacyParentalAllowedModules = count.clamp(0, 10);
    _prefs?.setInt('parentalAllowedModules', _legacyParentalAllowedModules);
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
