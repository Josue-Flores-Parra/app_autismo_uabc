import 'package:flutter_tts/flutter_tts.dart';

/// Servicio reutilizable para dictado con FlutterTts.
/// Centraliza la configuracion base para mantener una voz consistente.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isReady = false;

  bool get isReady => _isReady;

  /// Configuracion usada en minijuegos de aprendizaje.
  Future<bool> initializeDefaultEsMx() async {
    try {
      await _tts.setLanguage('es-MX');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
    return _isReady;
  }

  Future<void> speak(String? text) async {
    if (!_isReady) return;
    final content = text?.trim() ?? '';
    if (content.isEmpty) return;

    try {
      await _tts.stop();
      await _tts.speak(content);
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!_isReady) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }
}
