import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/services/celebration_helper.dart';
import '../../../shared/services/level_completion_service.dart';
import '../../../shared/widgets/video_control_rail.dart';
import '../../telemetry/model/telemetry_enums.dart';
import '../../telemetry/model/telemetry_signals.dart';
import '../viewmodel/video_viewmodel.dart';

/// Pantalla horizontal de reproducción de video para niveles de tipo 'video'.
/// Sustituye a _LevelVideoPlayerScreen (vista vertical) con el reproductor
/// horizontal que usa [VideoControlRail], igual que [_FullscreenVideoPlayer]
/// en preview_cards.dart.
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String levelTitle;
  final String? levelId;
  final String? moduleId;

  /// Handle opaco de telemetría (null si no hay consentimiento activo).
  final ActivitySessionHandle? telemetryHandle;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.levelTitle,
    this.levelId,
    this.moduleId,
    this.telemetryHandle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoViewModel _viewModel;
  late CelebrationHelper _celebrationHelper;

  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  bool _isCompleted = false;
  bool _hasNotifiedCompletion = false;
  bool _isFinishing = false;
  bool _readyEmitted = false;
  bool _hasAbandoned = false;

  static const Duration _kControlsAutoHide = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _celebrationHelper = CelebrationHelper();
    if (widget.videoUrl.isEmpty) {
      // Sin URL no hay nada que inicializar; se reporta como launch_error
      // en el primer frame para no interferir con el build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.telemetryHandle?.onLaunchError(
          TerminalReason.resourceInitializationFailed,
        );
      });
      return;
    }
    _viewModel = VideoViewModel();
    _viewModel.initialize(widget.videoUrl, null);
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.enterFullscreenMode(allowPortrait: true);
    _viewModel.initializeVideoFuture
        .then((_) {
          if (!mounted || _readyEmitted) return;
          _readyEmitted = true;
          widget.telemetryHandle?.onActivityReady();
        })
        .catchError((_) {
          if (!mounted || _readyEmitted) return;
          _readyEmitted = true;
          widget.telemetryHandle?.onLaunchError(
            TerminalReason.resourceInitializationFailed,
          );
        });
    _showControls();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    setState(() {});
    _checkCompletion();
  }

  void _checkCompletion() {
    if (_hasNotifiedCompletion) return;
    try {
      final controller = _viewModel.videoController;
      if (!controller.value.isInitialized) return;
      final duration = controller.value.duration;
      if (duration.inMilliseconds <= 0) return;
      final totalSeconds = duration.inMilliseconds / 1000.0;
      // actualSecondsWatched solo suma mientras el video reproduce de verdad
      // (ver VideoViewModel._updateWatchTime); a diferencia de controller.
      // value.position, no se puede completar arrastrando la barra de
      // progreso sin haber visto el video.
      if (_viewModel.actualSecondsWatched >= totalSeconds * 0.9) {
        _hasNotifiedCompletion = true;
        // Señal de objetivo al cruzar por primera vez el 90% (no terminaliza).
        widget.telemetryHandle?.onObjectiveMet();
        setState(() => _isCompleted = true);
        _hideControlsTimer?.cancel();
        if (!_controlsVisible) setState(() => _controlsVisible = true);
      }
    } catch (_) {}
  }

  void _showControls() {
    _hideControlsTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    if (_isCompleted) return;
    _hideControlsTimer = Timer(_kControlsAutoHide, () {
      if (!mounted || !_viewModel.videoController.value.isPlaying) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _onSurfaceTap() {
    _viewModel.togglePlayPause();
    _showControls();
  }

  void _replay() {
    // Tap explícito de replay → métrica.
    widget.telemetryHandle?.onRecordVideoReplay();
    _viewModel.replay();
    setState(() {
      _hasNotifiedCompletion = false;
      _isCompleted = false;
    });
    _showControls();
  }

  Future<void> _handleComplete() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    // Terminalizar telemetría antes de resetear, celebrar y esperar.
    widget.telemetryHandle?.onComplete();
    _hasAbandoned = true; // ya terminalizada: no volver a cerrar como abandono

    try {
      final controller = _viewModel.videoController;
      if (controller.value.isPlaying) await controller.pause();
      await controller.seekTo(Duration.zero);
    } catch (_) {}

    _celebrationHelper.playCelebration();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    await LevelCompletionService.showVideoCompletionDialog(
      context: context,
      moduleId: widget.moduleId,
      levelId: widget.levelId,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pauseAndPop() async {
    try {
      if (widget.videoUrl.isNotEmpty &&
          _viewModel.videoController.value.isInitialized &&
          _viewModel.videoController.value.isPlaying) {
        await _viewModel.videoController.pause();
      }
    } catch (_) {}
    // Abandona sólo si no se terminalizó ya (completar o error de carga).
    if (!_hasAbandoned) {
      _hasAbandoned = true;
      widget.telemetryHandle?.onAbandon(TerminalReason.userBack);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    if (widget.videoUrl.isNotEmpty) {
      _viewModel.removeListener(_onViewModelChanged);
      _viewModel.exitFullscreenMode();
      _viewModel.dispose();
    }
    _celebrationHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) {
      return _buildUnavailableScreen();
    }

    final controller = _viewModel.videoController;
    final isPlaying =
        controller.value.isInitialized && controller.value.isPlaying;
    final controlsOrCompleted = _controlsVisible || _isCompleted;
    // El sistema ahora sigue la rotación física (ver enterFullscreenMode):
    // en vertical los controles bajan al pie, tipo TikTok, para no depender
    // de que el niño sepa girar el teléfono.
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pauseAndPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onSurfaceTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          )
                        : const CircularProgressIndicator(
                            color: Colors.white38,
                          ),
                  ),
                  VideoTapFeedback(
                    visible: _viewModel.showGiantIcon,
                    isPlaying: isPlaying,
                  ),
                ],
              ),
            ),
            IgnorePointer(
              ignoring: !controlsOrCompleted,
              child: AnimatedOpacity(
                opacity: controlsOrCompleted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: _pauseAndPop,
                        ),
                      ),
                      if (isPortrait)
                        _buildBottomControls(controller, isPlaying)
                      else ...[
                        Positioned(
                          right: 18,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: VideoControlRail(
                              isPlaying: isPlaying,
                              isFullscreen: true,
                              onPlayPause: _onSurfaceTap,
                              onReplay: _replay,
                              onFullscreen: _pauseAndPop,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 80,
                          bottom: _isCompleted ? 80 : 14,
                          child: _buildProgressAndTime(controller),
                        ),
                        if (_isCompleted)
                          Positioned(
                            left: 16,
                            right: 80,
                            bottom: 14,
                            child: _buildCompletarButton(),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            CelebrationHelper.buildTopConfettiOverlay(
              controller: _celebrationHelper.confettiController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressAndTime(VideoPlayerController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Colors.white,
            bufferedColor: Colors.white38,
            backgroundColor: Colors.white24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_viewModel.formatDuration(controller.value.position)} / '
          '${_viewModel.formatDuration(controller.value.duration)}',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCompletarButton() {
    return ElevatedButton.icon(
      onPressed: _isFinishing ? null : _handleComplete,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      label: const Text(
        'COMPLETAR',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF05E995),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
        shadowColor: const Color(0x8005E995),
      ),
    );
  }

  /// Controles al pie, en horizontal, tipo TikTok: nada estorba el video y no
  /// depende de que el niño sepa que tiene que girar el teléfono para ver los
  /// botones. Reemplaza el riel vertical que se usa en horizontal.
  Widget _buildBottomControls(VideoPlayerController controller, bool isPlaying) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressAndTime(controller),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _replay,
                icon: const Icon(
                  Icons.replay_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _onSurfaceTap,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
          if (_isCompleted) ...[
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: _buildCompletarButton()),
          ],
        ],
      ),
    );
  }

  Widget _buildUnavailableScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'No hay video disponible para este nivel.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
