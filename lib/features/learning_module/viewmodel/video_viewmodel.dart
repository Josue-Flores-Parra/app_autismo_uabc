import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../data/video_controller_manager.dart';

class VideoViewModel extends ChangeNotifier {
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoFuture;
  bool _isExternalController = false;
  bool _showGiantIcon = false;
  Timer? _hideIconTimer;

  VideoPlayerController get videoController => _videoController;
  Future<void> get initializeVideoFuture => _initializeVideoFuture;
  bool get showGiantIcon => _showGiantIcon;

  void initialize(String videoPath, VideoPlayerController? externalController) {
    if (externalController != null) {
      _videoController = externalController;
      _isExternalController = true;
      _initializeVideoFuture = Future.value();
    } else {
      _videoController = VideoControllerManager().getOrCreateController(
        videoPath,
      );
      _isExternalController = true;
      if (_videoController.value.isInitialized) {
        _initializeVideoFuture = Future.value();
      } else {
        _initializeVideoFuture = _videoController.initialize().then((_) {
          _videoController.setLooping(true);
        });
      }
    }

    _videoController.addListener(() {
      notifyListeners();
    });
  }

  void togglePlayPause() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    _showTemporaryIcon();
  }

  void replay() {
    _videoController.seekTo(Duration.zero);
    _videoController.play();
    _showTemporaryIcon();
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
    if (!_isExternalController) {
      _videoController.dispose();
    }
    _hideIconTimer?.cancel();
    super.dispose();
  }
}
