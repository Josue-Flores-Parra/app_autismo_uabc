/// Espejo en memoria de los flags de feedback efectivos del perfil activo.
///
/// Los helpers de audio, TTS y vibracion no tienen `BuildContext`, por lo que
/// no pueden leer el provider. `SettingsViewModel` aplica los valores del
/// learner seleccionado (o defaults parent-wide sin learner) aquí y esos
/// servicios consultan los flags antes de reproducir.
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
