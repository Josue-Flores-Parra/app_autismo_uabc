import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../data/video_controller_manager.dart';

class VideoViewModel extends ChangeNotifier {
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoFuture;

  // Ruta del video gestionado por el manager (null si es controlador externo)
  String? _managedVideoPath;

  bool _showGiantIcon = false;
  Timer? _hideIconTimer;

  // Bandera para evitar llamar a notifyListeners() después de dispose()
  bool _isDisposed = false;

  // Referencia al listener para poder removerlo limpiamente en dispose()
  VoidCallback? _controllerListener;

  VideoPlayerController get videoController => _videoController;
  Future<void> get initializeVideoFuture => _initializeVideoFuture;
  bool get showGiantIcon => _showGiantIcon;

  void initialize(String videoPath, VideoPlayerController? externalController) {
    if (externalController != null) {
      // Controlador externo — no somos responsables de su ciclo de vida
      _videoController = externalController;
      _managedVideoPath = null;
      _initializeVideoFuture = Future.value();
    } else {
      // Obtener o crear un controlador compartido vía el manager (ref-counted)
      final manager = VideoControllerManager();
      _videoController = manager.getOrCreateController(videoPath);
      _managedVideoPath = videoPath;

      if (_videoController.value.isInitialized) {
        // Ya inicializado por otra referencia — reutilizar directamente
        _initializeVideoFuture = Future.value();
        // Asegurar loop desactivado sin carrera con otros ViewModels
        Future.microtask(() {
          if (!_isDisposed) _videoController.setLooping(false);
        });
      } else {
        // Primera vez que se inicializa este controlador
        _initializeVideoFuture = _videoController.initialize().then((_) {
          if (!_isDisposed) _videoController.setLooping(false);
        });
      }
    }

    // Registrar listener con guarda de disposed para evitar el crash
    // "VideoViewModel was used after being disposed"
    _controllerListener = () {
      if (!_isDisposed) notifyListeners();
    };
    // Diferir con microtask para no disparar setState() durante build()
    Future.microtask(() {
      if (!_isDisposed) {
        _videoController.addListener(_controllerListener!);
      }
    });
  }

  void togglePlayPause() {
    if (_isDisposed) return;
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    _showTemporaryIcon();
  }

  void replay() {
    if (_isDisposed) return;
    _videoController.seekTo(Duration.zero);
    _videoController.setLooping(false);
    _videoController.play();
    _showTemporaryIcon();
  }

  void pause() {
    if (_isDisposed) return;
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    }
  }

  void _showTemporaryIcon() {
    if (_isDisposed) return;
    _showGiantIcon = true;
    notifyListeners();

    _hideIconTimer?.cancel();
    _hideIconTimer = Timer(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        _showGiantIcon = false;
        notifyListeners();
      }
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void enterFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void exitFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideIconTimer?.cancel();

    // Remover el listener antes de liberar el controlador para evitar
    // que eventos posteriores lleguen a un ViewModel ya destruido
    if (_controllerListener != null) {
      try {
        _videoController.removeListener(_controllerListener!);
      } catch (_) {}
      _controllerListener = null;
    }

    // Liberar la referencia en el manager — solo dispone el controlador
    // subyacente cuando el conteo de referencias llega a cero
    if (_managedVideoPath != null) {
      VideoControllerManager().releaseController(_managedVideoPath!);
      _managedVideoPath = null;
    }

    super.dispose();
  }
}
