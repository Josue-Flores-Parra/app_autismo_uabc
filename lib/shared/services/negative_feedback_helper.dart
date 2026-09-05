import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Reusable negative feedback sound used by minigames when the player
/// fails (e.g. running out of attempts).
///
/// Sigue el mismo patrón de [CelebrationHelper]: encapsula la configuración
/// de la sesión de audio, la carga del asset y la reproducción, para que los
/// minijuegos no dupliquen esta lógica.
class NegativeFeedbackHelper {
  final AudioPlayer _player = AudioPlayer();

  /// Reproduce el sonido de fallo (`assets/audio/negative_beeps.mp3`).
  Future<void> playNegativeBeep() async {
    try {
      await _configureAudioSession();
      await _player.setAudioSource(
        AudioSource.asset('assets/audio/negative_beeps.mp3'),
      );
      await _player.setVolume(1.0);
      // Espera a que el audio termine de cargar antes de reproducirlo.
      if (_player.processingState == ProcessingState.loading) {
        await _player.playerStateStream
            .timeout(const Duration(seconds: 3))
            .firstWhere(
              (state) => state.processingState != ProcessingState.loading,
            );
      }
      await _player.play();
    } catch (_) {}
  }

  // Activa la sesión de audio para asegurar que el sonido se escuche.
  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
