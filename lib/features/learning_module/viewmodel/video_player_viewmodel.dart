import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerViewModel extends ChangeNotifier {
  late VideoPlayerController _controller;
  late Future<void> _initializeFuture;
  bool _showGiantIcon = false;
  Timer? _hideIconTimer;

  VideoPlayerController get controller => _controller;
  Future<void> get initializeFuture => _initializeFuture;
  bool get showGiantIcon => _showGiantIcon;

  void initialize(String videoPath) {
    if (videoPath.contains('http://') || videoPath.contains('https://')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
    } else {
      _controller = VideoPlayerController.asset(videoPath);
    }

    _initializeFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.addListener(() => notifyListeners());
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    showTemporaryIcon();
  }

  void replay() {
    _controller.seekTo(Duration.zero);
    _controller.play();
    showTemporaryIcon();
  }

  void showTemporaryIcon() {
    _showGiantIcon = true;
    notifyListeners();

    _hideIconTimer?.cancel();
    _hideIconTimer = Timer(const Duration(seconds: 2), () {
      _showGiantIcon = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideIconTimer?.cancel();
    super.dispose();
  }
}
