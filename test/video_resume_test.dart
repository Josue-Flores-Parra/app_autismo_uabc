import 'package:appy/features/learning_module/viewmodel/video_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeded watched seconds survive until the next reset', () {
    final viewModel = VideoViewModel();

    viewModel.seedWatchedSeconds(12.5);
    expect(viewModel.actualSecondsWatched, 12.5);

    viewModel.resetWatchedTime();
    expect(viewModel.actualSecondsWatched, 0.0);
  });

  test('a negative seed is clamped to zero', () {
    final viewModel = VideoViewModel();

    viewModel.seedWatchedSeconds(-3);

    expect(viewModel.actualSecondsWatched, 0.0);
  });
}
