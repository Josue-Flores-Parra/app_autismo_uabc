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
    
    _audioPlayer.playerStateStream.listen((_) {
      notifyListeners();
    });
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (e) {
      // Continuar de todas formas, puede que funcione sin la configuración
    }
  }

  Future<void> initialize(String audioPath) async {
    try {
      // Cargar el audio desde la URL o path
      if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
        await _audioPlayer.setUrl(audioPath);
        await _audioPlayer.setVolume(1.0);
      } else {
        // Para assets locales, usar AudioSource.asset()
        String assetPath = audioPath;
        
        // Asegurarse de que tenga el prefijo "assets/" si no lo tiene
        if (!assetPath.startsWith('assets/')) {
          assetPath = 'assets/$assetPath';
        }
        
        await _audioPlayer.setAudioSource(AudioSource.asset(assetPath));
        await _audioPlayer.setVolume(1.0);
      }
      
      _initializeAudioFuture = Future.value();
      notifyListeners();
    } catch (e) {
      _initializeAudioFuture = Future.error(e);
      rethrow; // Re-lanzar el error para que el minigame lo maneje
    }
  }

  Future<void> play() async {
    try {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (_) {}
      await _audioPlayer.setVolume(1.0);
      if (_audioPlayer.processingState == ProcessingState.loading) {
        try {
          await _audioPlayer.playerStateStream
              .timeout(const Duration(seconds: 10))
              .firstWhere(
            (state) => state.processingState != ProcessingState.loading,
          );
        } catch (_) {}
      }
      await _audioPlayer.play();
      _showTemporaryIcon();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _showTemporaryIcon();
      notifyListeners();
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      notifyListeners();
    } catch (_) {}
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

