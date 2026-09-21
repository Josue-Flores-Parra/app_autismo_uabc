/// Espejo en memoria de las preferencias de feedback de [SettingsViewModel].
///
/// Los helpers de audio, TTS y vibracion no tienen `BuildContext`, por lo que
/// no pueden leer el provider. `SettingsViewModel` publica aqui cada cambio y
/// esos servicios consultan estos flags antes de reproducir.
class FeedbackPreferences {
  static bool _audioEnabled = true;
  static bool _hapticsEnabled = true;

  static bool get audioEnabled => _audioEnabled;
  static bool get hapticsEnabled => _hapticsEnabled;

  static void setAudioEnabled(bool value) {
    _audioEnabled = value;
  }

  static void setHapticsEnabled(bool value) {
    _hapticsEnabled = value;
  }
}
