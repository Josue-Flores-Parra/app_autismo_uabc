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

  /// Obtiene el controlador existente para [videoPath] o crea uno nuevo.
  /// Incrementa el conteo de referencias. Llamar a [releaseController] al terminar.
  /// NO inicializa ni configura el loop — esa responsabilidad es del ViewModel.
  VideoPlayerController getOrCreateController(String videoPath) {
    if (_controllers.containsKey(videoPath)) {
      // Controlador ya existe — solo incrementar referencias
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

  /// Reduce el conteo de referencias para [videoPath].
  /// Solo dispone el controlador cuando el conteo llega a cero.
  void releaseController(String videoPath) {
    if (!_controllers.containsKey(videoPath)) return;

    final count = (_refCounts[videoPath] ?? 1) - 1;
    if (count <= 0) {
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
  }
}
