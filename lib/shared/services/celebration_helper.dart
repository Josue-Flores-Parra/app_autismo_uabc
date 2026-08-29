import 'package:audio_session/audio_session.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Reusable celebration effect used by minigames and video completion flows.
class CelebrationHelper {
  final ConfettiController confettiController;
  final AudioPlayer _celebrationPlayer = AudioPlayer();

  CelebrationHelper({Duration duration = const Duration(seconds: 3)})
    : confettiController = ConfettiController(duration: duration);

  Future<void> playCelebration() async {
    confettiController.play();
    await _playCelebrationSound();
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (_) {}
  }

  Future<void> _playCelebrationSound() async {
    try {
      await _configureAudioSession();
      await _celebrationPlayer.setAudioSource(
        AudioSource.asset('assets/audio/celebration.mp3'),
      );
      await _celebrationPlayer.setVolume(1.0);
      if (_celebrationPlayer.processingState == ProcessingState.loading) {
        await _celebrationPlayer.playerStateStream
            .timeout(const Duration(seconds: 3))
            .firstWhere(
              (state) => state.processingState != ProcessingState.loading,
            );
      }
      await _celebrationPlayer.play();
    } catch (_) {}
  }

  void dispose() {
    confettiController.dispose();
    _celebrationPlayer.dispose();
  }

  static Widget buildTopConfettiOverlay({
    required ConfettiController controller,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: 3.14 / 2,
        maxBlastForce: 5,
        minBlastForce: 2,
        emissionFrequency: 0.05,
        numberOfParticles: 50,
        gravity: 0.1,
        shouldLoop: false,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple,
          Colors.yellow,
          Colors.red,
        ],
      ),
    );
  }
}
