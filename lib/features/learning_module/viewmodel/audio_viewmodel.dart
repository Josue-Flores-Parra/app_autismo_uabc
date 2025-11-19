import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioViewModel extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  late Future<void> _initializeAudioFuture;
  bool _showGiantIcon = false;
  Timer? _hideIconTimer;

  AudioPlayer get audioPlayer => _audioPlayer;
  Future<void> get initializeAudioFuture => _initializeAudioFuture;
  bool get showGiantIcon => _showGiantIcon;
  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;
  double get volume => _audioPlayer.volume;

  AudioViewModel() {
    _audioPlayer = AudioPlayer();
    _initializeAudioFuture = Future.value();
    
    // Configurar sesión de audio para Android
    _configureAudioSession();
    
    // Asegurar que el volumen inicial sea 1.0 (100%)
    _audioPlayer.setVolume(1.0);
    
    // Escuchar cambios en el estado del audio
    _audioPlayer.positionStream.listen((_) {
      notifyListeners();
    });
    
    _audioPlayer.playerStateStream.listen((state) {
      debugPrint('AudioPlayer state: playing=${state.playing}, processingState=${state.processingState}');
      notifyListeners();
    });
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      debugPrint('Sesión de audio configurada y activada correctamente');
    } catch (e) {
      debugPrint('Error al configurar sesión de audio: $e');
      // Continuar de todas formas, puede que funcione sin la configuración
    }
  }

  Future<void> initialize(String audioPath) async {
    try {
      // Cargar el audio desde la URL o path
      if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
        debugPrint('Intentando cargar audio desde URL: $audioPath');
        await _audioPlayer.setUrl(audioPath);
        debugPrint('Audio cargado exitosamente desde URL: $audioPath');
        debugPrint('Duración del audio: ${_audioPlayer.duration}');
        debugPrint('Volumen actual: ${_audioPlayer.volume}');
        
        // Asegurar que el volumen esté en 1.0 después de cargar
        await _audioPlayer.setVolume(1.0);
        debugPrint('Volumen configurado a: ${_audioPlayer.volume}');
      } else {
        // Para assets locales, usar AudioSource.asset()
        String assetPath = audioPath;
        
        // Asegurarse de que tenga el prefijo "assets/" si no lo tiene
        if (!assetPath.startsWith('assets/')) {
          assetPath = 'assets/$assetPath';
        }
        
        debugPrint('Intentando cargar audio desde asset: $assetPath (original: $audioPath)');
        
        // Usar AudioSource.asset() que es el método correcto para assets locales
        await _audioPlayer.setAudioSource(AudioSource.asset(assetPath));
        
        debugPrint('Audio cargado exitosamente desde asset: $assetPath');
        debugPrint('Duración del audio: ${_audioPlayer.duration}');
        debugPrint('Volumen actual: ${_audioPlayer.volume}');
        
        // Asegurar que el volumen esté en 1.0 después de cargar
        await _audioPlayer.setVolume(1.0);
        debugPrint('Volumen configurado a: ${_audioPlayer.volume}');
      }
      
      _initializeAudioFuture = Future.value();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al inicializar audio: $e');
      debugPrint('Ruta del audio original: $audioPath');
      _initializeAudioFuture = Future.error(e);
      rethrow; // Re-lanzar el error para que el minigame lo maneje
    }
  }

  Future<void> play() async {
    try {
      debugPrint('Intentando reproducir audio...');
      debugPrint('Estado antes de play: playing=${_audioPlayer.playing}, volume=${_audioPlayer.volume}');
      debugPrint('Duración del audio: ${_audioPlayer.duration}');
      debugPrint('Posición actual: ${_audioPlayer.position}');
      debugPrint('ProcessingState: ${_audioPlayer.processingState}');
      
      // Asegurar que la sesión de audio esté activa
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
        debugPrint('Sesión de audio activada antes de reproducir');
      } catch (e) {
        debugPrint('Error al activar sesión de audio: $e');
      }
      
      // Asegurar que el volumen esté en 1.0 antes de reproducir
      await _audioPlayer.setVolume(1.0);
      
      // Esperar a que el audio esté listo si está cargando
      if (_audioPlayer.processingState == ProcessingState.loading) {
        debugPrint('Audio aún cargando, esperando...');
        try {
          await _audioPlayer.playerStateStream
              .timeout(const Duration(seconds: 10))
              .firstWhere(
            (state) => state.processingState != ProcessingState.loading,
          );
        } catch (e) {
          debugPrint('Timeout esperando a que el audio cargue: $e');
          // Continuar de todas formas, el audio podría estar listo
        }
      }
      
      await _audioPlayer.play();
      debugPrint('Audio play() llamado exitosamente');
      _showTemporaryIcon();
      notifyListeners();
      
      // Verificar después de un momento si realmente está reproduciendo
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('Estado después de play: playing=${_audioPlayer.playing}, processingState=${_audioPlayer.processingState}');
        if (!_audioPlayer.playing) {
          debugPrint('⚠️ ADVERTENCIA: El audio no se está reproduciendo después de play()');
        }
      });
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _showTemporaryIcon();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al pausar audio: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> replay() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      _showTemporaryIcon();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al reiniciar audio: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al buscar posición: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cambiar volumen: $e');
    }
  }

  void _showTemporaryIcon() {
    _showGiantIcon = true;
    notifyListeners();

    _hideIconTimer?.cancel();
    _hideIconTimer = Timer(const Duration(seconds: 2), () {
      _showGiantIcon = false;
      notifyListeners();
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideIconTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

