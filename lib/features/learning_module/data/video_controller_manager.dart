import 'package:video_player/video_player.dart';

/// Gestiona un único VideoPlayerController por URL mediante conteo de referencias.
/// Esto evita que múltiples widgets creen instancias paralelas del decodificador
/// de hardware (ExoPlayer), lo cual agota la RAM en dispositivos de gama baja.
class VideoControllerManager {
  static final VideoControllerManager _instance =
      VideoControllerManager._internal();

  factory VideoControllerManager() => _instance;

  VideoControllerManager._internal();

  final Map<String, VideoPlayerController> _controllers = {};
  // Conteo de referencias: cuántos ViewModels están usando cada controlador
  final Map<String, int> _refCounts = {};
  // Evita inicializaciones concurrentes del mismo controlador para la misma URL.
  // Esto es clave cuando hay precarga en background y apertura de popup casi simultánea.
  final Map<String, Future<void>> _initializationFutures = {};

  /// Obtiene el controlador existente para [videoPath] o crea uno nuevo.
  /// Incrementa el conteo de referencias. Llamar a [releaseController] al terminar.
  /// NO inicializa ni configura el loop — esa responsabilidad es del ViewModel.
  VideoPlayerController getOrCreateController(String videoPath) {
    if (_controllers.containsKey(videoPath)) {
      // Cache hit: reutilizamos el mismo decoder/stream y solo incrementamos refCount.
      _refCounts[videoPath] = (_refCounts[videoPath] ?? 0) + 1;
      return _controllers[videoPath]!;
    }

    // Crear nuevo controlador sin inicializarlo ni configurarlo aquí
    VideoPlayerController controller;
    if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
    } else {
      controller = VideoPlayerController.asset(videoPath);
    }

    _controllers[videoPath] = controller;
    _refCounts[videoPath] = 1;

    return controller;
  }

  /// Inicializa en segundo plano el controlador asociado a [videoPath].
  /// Si ya está inicializado o inicializando, reutiliza ese estado.
  Future<void> initializeController(String videoPath) {
    final controller = _controllers[videoPath];
    if (controller == null) {
      return Future.error(
        StateError('Controller for "$videoPath" does not exist.'),
      );
    }

    if (controller.value.isInitialized) {
      // Ya inicializado por otra vista/VM: no repetir trabajo.
      return Future.value();
    }

    final existingFuture = _initializationFutures[videoPath];
    if (existingFuture != null) {
      // Ya hay una inicialización en curso para este video.
      return existingFuture;
    }

    final future = controller.initialize().whenComplete(() {
      _initializationFutures.remove(videoPath);
    });
    _initializationFutures[videoPath] = future;
    return future;
  }

  /// Reduce el conteo de referencias para [videoPath].
  /// Solo dispone el controlador cuando el conteo llega a cero.
  void releaseController(String videoPath) {
    if (!_controllers.containsKey(videoPath)) return;

    final count = (_refCounts[videoPath] ?? 1) - 1;
    if (count <= 0) {
      // Última referencia: liberar recursos nativos de video.
      _initializationFutures.remove(videoPath);
      _controllers[videoPath]?.dispose();
      _controllers.remove(videoPath);
      _refCounts.remove(videoPath);
    } else {
      _refCounts[videoPath] = count;
    }
  }

  /// Dispone todos los controladores (usar al cerrar sesión o destruir la app).
  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _refCounts.clear();
    _initializationFutures.clear();
  }
}
