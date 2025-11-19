import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import '../../minigame_core.dart';
import '../../../learning_module/viewmodel/video_viewmodel.dart';

/// Minijuego de Video
/// Reproduce un video tutorial completo como actividad del nivel
/// El usuario debe ver el video y luego presionar "Completar" para finalizar
class VideoMinigame extends MinigameBase {
  const VideoMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
  });

  @override
  State<VideoMinigame> createState() => _VideoMinigameState();
}

class _VideoMinigameState extends State<VideoMinigame> {
  VideoViewModel? _viewModel;
  bool _isCompleted = false;
  bool _hasStartedPlaying = false;
  Timer? _completionCheckTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    // Obtener la URL del video desde minigameData
    final videoUrl = widget.minigameData['videoUrl'] as String?;
    
    if (videoUrl == null || videoUrl.isEmpty) {
      // Si no hay video, completar inmediatamente con error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          widget.onComplete(false, 1);
        }
      });
      return;
    }

    _viewModel = VideoViewModel();
    _viewModel!.initialize(videoUrl, null);
    _viewModel!.addListener(_onVideoStateChanged);
    
    // Iniciar reproducción automática y desactivar loop
    _viewModel!.initializeVideoFuture.then((_) {
      if (mounted && !_isDisposed && _viewModel != null) {
        try {
          // Desactivar loop para el minigame (el video se reproduce una vez)
          _viewModel!.videoController.setLooping(false);
          _viewModel!.videoController.play();
          setState(() {
            _hasStartedPlaying = true;
          });
        } catch (e) {
          // El viewModel puede haber sido disposed
          debugPrint('Error al iniciar video: $e');
        }
      }
    }).catchError((error) {
      debugPrint('Error al inicializar video: $error');
    });

    // Iniciar timer para verificar si el video se completó
    _startCompletionCheck();
  }

  void _startCompletionCheck() {
    _completionCheckTimer?.cancel();
    _completionCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _isDisposed || _viewModel == null) {
        timer.cancel();
        return;
      }

      try {
        final controller = _viewModel!.videoController;
        if (controller.value.isInitialized) {
          final position = controller.value.position;
          final duration = controller.value.duration;
          
          // Verificar si el video se completó (al menos 90% visto)
          if (duration.inMilliseconds > 0) {
            final progress = position.inMilliseconds / duration.inMilliseconds;
            if (progress >= 0.9 && !_isCompleted) {
              // El usuario ha visto al menos el 90% del video
              // No completamos automáticamente, pero habilitamos el botón
              if (mounted && !_isDisposed) {
                setState(() {
                  // El botón ya está habilitado, solo actualizamos el estado si es necesario
                });
              }
            }
          }
        }
      } catch (e) {
        // El viewModel puede haber sido disposed
        timer.cancel();
        debugPrint('Error en completion check: $e');
      }
    });
  }

  void _onVideoStateChanged() {
    if (mounted && !_isDisposed && _viewModel != null) {
      setState(() {});
    }
  }

  void _handleComplete() {
    if (_isCompleted || _isDisposed || _viewModel == null) return;
    
    setState(() {
      _isCompleted = true;
    });
    
    try {
      // Pausar el video
      if (_viewModel!.videoController.value.isPlaying) {
        _viewModel!.videoController.pause();
      }
    } catch (e) {
      debugPrint('Error al pausar video: $e');
    }
    
    // Llamar al callback de completado
    widget.onComplete(true, 1);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _completionCheckTimer?.cancel();
    _completionCheckTimer = null;
    
    if (_viewModel != null) {
      try {
        _viewModel!.removeListener(_onVideoStateChanged);
        _viewModel!.dispose();
      } catch (e) {
        debugPrint('Error al dispose viewModel: $e');
      }
      _viewModel = null;
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null || _isDisposed) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5B8DB3),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder(
          future: _viewModel!.initializeVideoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5B8DB3),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar el video',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              );
            }

            return _buildVideoPlayer();
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_viewModel == null || _isDisposed) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5B8DB3),
        ),
      );
    }

    final controller = _viewModel!.videoController;
    final aspectRatio = controller.value.aspectRatio;

    return Column(
      children: [
        // Video player
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayer(controller),

                  // Overlay con icono de play/pause
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        if (_viewModel != null && !_isDisposed) {
                          _viewModel!.togglePlayPause();
                        }
                      },
                      child: AnimatedOpacity(
                        opacity: (_viewModel?.showGiantIcon ?? false) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Center(
                          child: SvgPicture.asset(
                            controller.value.isPlaying
                                ? 'assets/icons/pausebigbutton.svg'
                                : 'assets/icons/playbigbutton.svg',
                            width: 80.0,
                            height: 80.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Barra de progreso
                  Positioned(
                    bottom: 60,
                    left: 10,
                    right: 10,
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white54,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Controles y botón de completar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1A3D52),
            border: Border(
              top: BorderSide(color: Color(0x66FFFFFF), width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Controles de video
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      controller.value.isPlaying
                          ? 'assets/icons/pausebutton.svg'
                          : 'assets/icons/playbuttoncontroller.svg',
                      width: 30,
                      height: 30,
                    ),
                    onPressed: () {
                      if (_viewModel != null && !_isDisposed) {
                        _viewModel!.togglePlayPause();
                      }
                    },
                  ),
                  Text(
                    _viewModel != null && !_isDisposed
                        ? '${_viewModel!.formatDuration(controller.value.position)} / ${_viewModel!.formatDuration(controller.value.duration)}'
                        : '00:00 / 00:00',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      'assets/icons/replay.svg',
                      width: 30,
                      height: 30,
                    ),
                    onPressed: () {
                      if (_viewModel != null && !_isDisposed) {
                        _viewModel!.replay();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botón de completar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompleted ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCompleted
                        ? Colors.grey
                        : const Color(0xFF05E995),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCompleted ? Icons.check_circle : Icons.check,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCompleted ? 'Completado' : 'Completar',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Registrar este minijuego con el factory
/// Debe ser llamado durante la inicialización de la app (main.dart)
void registerVideoMinigame() {
  MinigameFactory.register(
    MinigameType.video,
    ({required onComplete, required minigameData}) => VideoMinigame(
      onComplete: onComplete,
      minigameData: minigameData,
    ),
  );
}

