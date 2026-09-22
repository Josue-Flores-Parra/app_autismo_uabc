import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../data/video_controller_manager.dart';

class VideoViewModel extends ChangeNotifier {
  VideoViewModel({DateTime Function()? now}) : _now = now ?? DateTime.now;

  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoFuture;
  final DateTime Function() _now;

  // Ruta del video gestionado por el manager (null si es controlador externo)
  String? _managedVideoPath;

  bool _showGiantIcon = false;
  Timer? _hideIconTimer;

  // Bandera para evitar llamar a notifyListeners() después de dispose()
  bool _isDisposed = false;

  // Referencia al listener para poder removerlo limpiamente en dispose()
  VoidCallback? _controllerListener;

  // Solo contabiliza reproducción real; la actividad usa este valor para no
  // habilitar COMPLETAR al adelantar la barra de progreso.
  double _actualSecondsWatched = 0.0;
  DateTime? _lastTick;

  double get actualSecondsWatched => _actualSecondsWatched;

  /// Starts a fresh activity viewing session without replacing the shared
  /// native controller.
  void resetWatchedTime() {
    if (_isDisposed) return;
    // También se limpia _lastTick para que el primer evento tras replay no
    // acumule el intervalo de la reproducción anterior.
    _actualSecondsWatched = 0.0;
    _lastTick = null;
  }

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
        // Inicialización compartida para evitar carreras entre:
        // - precarga en background desde el carrusel
        // - apertura inmediata de la tarjeta/popup de video
        _initializeVideoFuture = manager.initializeController(videoPath).then((
          _,
        ) {
          if (!_isDisposed) _videoController.setLooping(false);
        });
      }
    }

    // Registrar listener con guarda de disposed para evitar el crash
    // "VideoViewModel was used after being disposed"
    _controllerListener = () {
      if (!_isDisposed) {
        _updateWatchTime();
        notifyListeners();
      }
    };
    // Diferir con microtask para no disparar setState() durante build()
    Future.microtask(() {
      if (!_isDisposed) {
        _videoController.addListener(_controllerListener!);
      }
    });
  }

  void _updateWatchTime() {
    if (_videoController.value.isPlaying) {
      final now = _now();
      if (_lastTick != null) {
        _actualSecondsWatched +=
            now.difference(_lastTick!).inMilliseconds / 1000.0;
      }
      _lastTick = now;
    } else {
      _lastTick = null;
    }
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

  /// Restarts playback as a fresh viewing pass.
  ///
  /// The watched-time reset is deliberately synchronous, before the first
  /// await, so a controller notification cannot carry eligibility from the
  /// previous pass into the replayed one.
  Future<void> replay() async {
    if (_isDisposed) return;
    resetWatchedTime();

    try {
      if (_videoController.value.isPlaying) {
        await _videoController.pause();
      }
      if (_isDisposed) return;
      await _videoController.seekTo(Duration.zero);
      if (_isDisposed) return;
      await _videoController.setLooping(false);
      if (_isDisposed) return;
      await _videoController.play();
    } finally {
      if (!_isDisposed) _showTemporaryIcon();
    }
  }

  void pause() {
    if (_isDisposed) return;
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    }
  }

  void _showTemporaryIcon() {
    if (_isDisposed) return;
    // Feedback visual corto al usuario (play/pause) sin ensuciar la UI permanente.
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

  /// [allowPortrait] deja que el sistema siga la rotación física del
  /// teléfono en vez de forzar horizontal: hay niños con TEA que no saben
  /// girar el teléfono para "entrar" al video, así que debe poder verse en
  /// cualquier orientación, igual que en cualquier otra app de video.
  ///
  /// La lista de 3 orientaciones (vertical + las dos horizontales, sin
  /// vertical invertida) no corresponde a ninguna combinación que Android
  /// reconozca como válida; el motor de Flutter la reduce a solo la primera
  /// orientación de la lista y el video quedaba forzado, no libre. Con las 4
  /// orientaciones sí es una combinación reconocida (rotación libre real).
  void enterFullscreenMode({bool allowPortrait = false}) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
      allowPortrait
          ? const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );
  }

  void exitFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // La app es solo vertical (ver main.dart): al salir se vuelve a fijar.
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
