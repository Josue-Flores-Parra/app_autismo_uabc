import 'package:appy/features/learning_module/viewmodel/video_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class _FakeVideoController extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _FakeVideoController()
    : super(
        const VideoPlayerValue(
          duration: Duration(seconds: 100),
          isInitialized: true,
        ),
      );

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  int playerId = VideoPlayerController.kUninitializedPlayerId;

  @override
  String get dataSource => '';

  @override
  Map<String, String> get httpHeaders => const {};

  @override
  DataSourceType get dataSourceType => DataSourceType.asset;

  @override
  String get package => '';

  @override
  Future<Duration> get position async => value.position;

  @override
  VideoViewType get viewType => VideoViewType.textureView;

  @override
  VideoFormat? get formatHint => null;

  @override
  VideoPlayerOptions? get videoPlayerOptions => null;

  @override
  Future<ClosedCaptionFile> get closedCaptionFile async =>
      _FakeClosedCaptionFile();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> seekTo(Duration moment) async {
    value = value.copyWith(position: moment);
  }

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  void setCaptionOffset(Duration delay) {}

  @override
  Future<void> setClosedCaptionFile(
    Future<ClosedCaptionFile>? closedCaptionFile,
  ) async {}

  void advanceTo(Duration position) {
    value = value.copyWith(position: position, isPlaying: true);
  }
}

class _FakeClosedCaptionFile extends ClosedCaptionFile {
  @override
  List<Caption> get captions => const [];
}

void main() {
  test('replay clears watched time before restarting playback', () async {
    var now = DateTime(2026, 1, 1, 12);
    final controller = _FakeVideoController();
    final viewModel = VideoViewModel(now: () => now);
    addTearDown(() {
      viewModel.dispose();
      controller.dispose();
    });

    viewModel.initialize('', controller);
    await Future<void>.delayed(Duration.zero);

    await controller.play();
    now = now.add(const Duration(seconds: 60));
    controller.advanceTo(const Duration(seconds: 60));
    expect(viewModel.actualSecondsWatched, 60);

    final replay = viewModel.replay();
    expect(viewModel.actualSecondsWatched, 0);
    await replay;
    expect(controller.value.position, Duration.zero);
    expect(controller.value.isPlaying, isTrue);

    now = now.add(const Duration(seconds: 30));
    controller.advanceTo(const Duration(seconds: 30));
    expect(viewModel.actualSecondsWatched, 30);
    expect(viewModel.actualSecondsWatched, lessThan(90));
  });
}
