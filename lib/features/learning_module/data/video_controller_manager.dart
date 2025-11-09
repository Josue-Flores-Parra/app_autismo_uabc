import 'package:video_player/video_player.dart';

class VideoControllerManager {
  static final VideoControllerManager _instance =
      VideoControllerManager._internal();

  factory VideoControllerManager() => _instance;

  VideoControllerManager._internal();

  final Map<String, VideoPlayerController> _controllers = {};

  VideoPlayerController getOrCreateController(String videoPath) {
    if (_controllers.containsKey(videoPath)) {
      return _controllers[videoPath]!;
    }

    VideoPlayerController controller;
    if (videoPath.contains('http://') || videoPath.contains('https://')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
    } else {
      controller = VideoPlayerController.asset(videoPath);
    }

    controller.initialize();
    controller.setLooping(true);
    _controllers[videoPath] = controller;

    return controller;
  }

  void disposeController(String videoPath) {
    if (_controllers.containsKey(videoPath)) {
      _controllers[videoPath]?.dispose();
      _controllers.remove(videoPath);
    }
  }

  void disposeAll() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}
