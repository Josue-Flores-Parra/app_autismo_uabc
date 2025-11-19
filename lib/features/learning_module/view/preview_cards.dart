import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodel/video_viewmodel.dart';
import '../viewmodel/audio_viewmodel.dart';

class BasePreviewCard extends StatefulWidget {
  final Widget typeOfPreviewCard;
  final bool isPreview;

  const BasePreviewCard({
    super.key,
    required this.typeOfPreviewCard,
    this.isPreview = true,
  });

  @override
  State<StatefulWidget> createState() => _BasePreviewCardState();
}

class _BasePreviewCardState extends State<BasePreviewCard>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE65B8DB3), Color(0xCC4A7499)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x997BA5C9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC2A4A5C),
            blurRadius: 25,
            offset: Offset(0, 12),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 35,
            offset: Offset(0, 18),
            spreadRadius: -5,
          ),
        ],
      ),
      child: widget.typeOfPreviewCard,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class PictogramPreviewCard extends StatefulWidget {
  final String imgPreview;
  final String pictogramTitle;
  final String pictogramDesc;
  final bool isPreview;
  final VoidCallback? onPictogramViewed; // Callback cuando se ve por 10 segundos

  const PictogramPreviewCard({
    super.key,
    required this.imgPreview,
    required this.pictogramTitle,
    required this.pictogramDesc,
    this.isPreview = true,
    this.onPictogramViewed,
  });

  @override
  State<StatefulWidget> createState() => _PictogramPreviewCardState();
}

class _PictogramPreviewCardState extends State<PictogramPreviewCard>
    with AutomaticKeepAliveClientMixin {
  Timer? _viewTimer;
  bool _hasNotified = false;
  DateTime? _fullscreenStartTime;

  @override
  void initState() {
    super.initState();
    // Solo iniciar timer si NO es preview (es decir, está en fullscreen)
    // El timer se iniciará cuando se detecte que isPreview cambió a false
    if (!widget.isPreview) {
      _startViewTimer();
    }
  }

  @override
  void didUpdateWidget(PictogramPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió de preview a fullscreen, iniciar el timer
    if (oldWidget.isPreview && !widget.isPreview && !_hasNotified) {
      _startViewTimer();
    }
  }

  void _startViewTimer() {
    // Cancelar timer anterior si existe
    _viewTimer?.cancel();
    _fullscreenStartTime = DateTime.now();
    
    // Iniciar timer para rastrear tiempo de visualización (10 segundos)
    _viewTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_hasNotified && widget.onPictogramViewed != null) {
        _hasNotified = true;
        widget.onPictogramViewed!();
      }
    });
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);

    return BasePreviewCard(
      isPreview: widget.isPreview,
      typeOfPreviewCard: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x997BA5C9), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: widget.imgPreview.isNotEmpty
                      ? _buildImageFromUrl(widget.imgPreview, fit: BoxFit.contain)
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.pictogramTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            if (widget.pictogramDesc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.pictogramDesc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xE6FFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 16),

            // El botón se oculta porque el clic en la tarjeta completa ya navega a fullscreen
            // El botón era redundante y causaba confusión
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class VideoPreviewCard extends StatefulWidget {
  final String videoPath;
  final String videoTitle;
  final String? videoDesc;
  final bool isPreview;
  final VideoPlayerController? externalController;
  final VoidCallback? onVideoCompleted; // Callback cuando el video se completa

  const VideoPreviewCard({
    super.key,
    required this.videoPath,
    required this.videoTitle,
    this.videoDesc,
    this.isPreview = true,
    this.externalController,
    this.onVideoCompleted,
  });

  @override
  State<VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<VideoPreviewCard>
    with AutomaticKeepAliveClientMixin {
  late VideoViewModel _viewModel;
  bool _hasNotifiedCompletion = false;
  Timer? _completionCheckTimer;

  @override
  void initState() {
    super.initState();
    _viewModel = VideoViewModel();
    _viewModel.initialize(widget.videoPath, widget.externalController);
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
    
    // Verificar periódicamente si el video se completó
    _completionCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _hasNotifiedCompletion) return;
      
      try {
        final controller = _viewModel.videoController;
        if (controller.value.isInitialized) {
          final position = controller.value.position;
          final duration = controller.value.duration;
          
          // Verificar si el video se completó (al menos 90% visto o llegó al final)
          if (duration.inMilliseconds > 0) {
            final progress = position.inMilliseconds / duration.inMilliseconds;
            final isAtEnd = position >= duration;
            
            if ((progress >= 0.9 || isAtEnd) && !_hasNotifiedCompletion) {
              _hasNotifiedCompletion = true;
              // NO cancelar el timer completamente, solo marcar como notificado
              // Esto permite que el usuario pueda volver a reproducir el video
              
              // Detener el video cuando se completa (pero permitir reproducirlo de nuevo)
              try {
                // Asegurarse de que el loop esté desactivado
                if (controller.value.isLooping) {
                  controller.setLooping(false);
                }
                // Solo pausar si el video llegó al final y está reproduciéndose
                // Esto permite que el usuario pueda reproducirlo de nuevo fácilmente
                if (isAtEnd && controller.value.isPlaying) {
                  controller.pause();
                }
              } catch (e) {
                // Error al pausar, continuar
              }
              
              if (widget.onVideoCompleted != null) {
                widget.onVideoCompleted!();
              }
            }
            
            // Si el usuario vuelve a reproducir el video después de completarlo,
            // permitir que se pueda completar de nuevo (resetear el flag si el video se reinicia)
            if (_hasNotifiedCompletion && position < duration * 0.5) {
              // Si el video se reinició (volvió al inicio), permitir completarlo de nuevo
              _hasNotifiedCompletion = false;
            }
          }
        }
      } catch (e) {
        // Error al verificar, continuar
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder(
      future: _viewModel.initializeVideoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return BasePreviewCard(
            isPreview: widget.isPreview,
            typeOfPreviewCard: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double videoAspectRatio =
                            _viewModel.videoController.value.aspectRatio;
                        final double availableWidth = constraints.maxWidth;
                        final double videoHeight =
                            availableWidth / videoAspectRatio;
                        final double controlBarHeight = videoHeight * 0.15;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: videoAspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                VideoPlayer(_viewModel.videoController),

                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: _viewModel.togglePlayPause,
                                    child: AnimatedOpacity(
                                      opacity: _viewModel.showGiantIcon
                                          ? 1.0
                                          : 0.0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: SvgPicture.asset(
                                        _viewModel
                                                .videoController
                                                .value
                                                .isPlaying
                                            ? 'assets/icons/pausebigbutton.svg'
                                            : 'assets/icons/playbigbutton.svg',
                                        width: 60.0,
                                        height: 60.0,
                                      ),
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: controlBarHeight + 10.0,
                                  left: 0,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: VideoProgressIndicator(
                                      _viewModel.videoController,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.white,
                                        bufferedColor: Colors.white54,
                                        backgroundColor: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: controlBarHeight,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5B8DB3),
                                      border: Border(
                                        top: BorderSide(
                                          width: 3.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: SvgPicture.asset(
                                            _viewModel
                                                    .videoController
                                                    .value
                                                    .isPlaying
                                                ? 'assets/icons/pausebutton.svg'
                                                : 'assets/icons/playbuttoncontroller.svg',
                                            width: 30,
                                            height: 30,
                                          ),
                                          onPressed: _viewModel.togglePlayPause,
                                        ),

                                        Text(
                                          '${_viewModel.formatDuration(_viewModel.videoController.value.position)} / ${_viewModel.formatDuration(_viewModel.videoController.value.duration)}',
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
                                          onPressed: _viewModel.replay,
                                        ),

                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: SvgPicture.asset(
                                            'assets/icons/fullscreen.svg',
                                            width: 30,
                                            height: 30,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    _FullscreenVideoPlayer(
                                                      viewModel: _viewModel,
                                                      onClose: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.videoTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (widget.videoDesc != null && widget.videoDesc!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.videoDesc!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xE6FFFFFF),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _completionCheckTimer?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoViewModel viewModel;
  final VoidCallback onClose;

  const _FullscreenVideoPlayer({
    required this.viewModel,
    required this.onClose,
  });

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.enterFullscreenMode();
    widget.viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.viewModel.exitFullscreenMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.viewModel.videoController.value.aspectRatio,
              child: VideoPlayer(widget.viewModel.videoController),
            ),
          ),

          Positioned.fill(
            child: GestureDetector(
              onTap: widget.viewModel.togglePlayPause,
              child: AnimatedOpacity(
                opacity: widget.viewModel.showGiantIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: SvgPicture.asset(
                  widget.viewModel.videoController.value.isPlaying
                      ? 'assets/icons/pausebigbutton.svg'
                      : 'assets/icons/playbigbutton.svg',
                  width: 80.0,
                  height: 80.0,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 60,
            left: 10,
            right: 10,
            child: VideoProgressIndicator(
              widget.viewModel.videoController,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.white24,
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(color: Color(0xFF5B8DB3)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      widget.viewModel.videoController.value.isPlaying
                          ? 'assets/icons/pausebutton.svg'
                          : 'assets/icons/playbuttoncontroller.svg',
                      width: 30,
                      height: 30,
                    ),
                    onPressed: widget.viewModel.togglePlayPause,
                  ),

                  Text(
                    '${widget.viewModel.formatDuration(widget.viewModel.videoController.value.position)} / ${widget.viewModel.formatDuration(widget.viewModel.videoController.value.duration)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      'assets/icons/replay.svg',
                      width: 30,
                      height: 30,
                    ),
                    onPressed: widget.viewModel.replay,
                  ),

                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      'assets/icons/fullscreen.svg',
                      width: 30,
                      height: 30,
                    ),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniGamePreviewCard extends StatefulWidget {
  final String gameTitle;
  final String imgPreview;
  final String? gameDesc;
  final bool isPreview;

  const MiniGamePreviewCard({
    super.key,
    required this.gameTitle,
    required this.imgPreview,
    this.gameDesc,
    this.isPreview = true,
  });

  @override
  State<MiniGamePreviewCard> createState() => _MiniGamePreviewCardState();
}

class _MiniGamePreviewCardState extends State<MiniGamePreviewCard>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BasePreviewCard(
      isPreview: widget.isPreview,
      typeOfPreviewCard: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x997BA5C9), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    widget.imgPreview,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, obj, trace) => const Center(
                      child: Icon(
                        Icons.gamepad_rounded,
                        size: 80,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.gameTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            if (widget.gameDesc != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.gameDesc!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xE6FFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 16),

            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF92C5BC), Color(0xFF5A97B8)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFB0D9D1), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4DFFFFFF),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x665A97B8),
                    blurRadius: 15,
                    offset: Offset(0, 0),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {},
                  child: const Center(
                    child: Text(
                      '¡JUGAR!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFFFFF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class AudioPreviewCard extends StatefulWidget {
  final String audioPath;
  final String audioTitle;
  final String? audioDesc;
  final bool isPreview;
  final String? imagePath;
  final VoidCallback? onAudioCompleted; // Callback cuando el audio se completa

  const AudioPreviewCard({
    super.key,
    required this.audioPath,
    required this.audioTitle,
    this.audioDesc,
    this.isPreview = true,
    this.imagePath,
    this.onAudioCompleted,
  });

  @override
  State<AudioPreviewCard> createState() => _AudioPreviewCardState();
}

class _AudioPreviewCardState extends State<AudioPreviewCard>
    with AutomaticKeepAliveClientMixin {
  late AudioViewModel _viewModel;
  bool _hasNotifiedCompletion = false;
  Timer? _completionCheckTimer;

  @override
  void initState() {
    super.initState();
    _viewModel = AudioViewModel();
    _viewModel.initialize(widget.audioPath).then((_) {
      if (mounted) setState(() {});
    }).catchError((error) {
      debugPrint('Error al inicializar audio: $error');
    });
    
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
    
    // Verificar periódicamente si el audio se completó
    _completionCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      
      try {
        final position = _viewModel.position;
        final duration = _viewModel.duration;
        
        // Verificar si el audio se completó (al menos 90% visto o llegó al final)
        if (duration != null && duration.inMilliseconds > 0) {
          final progress = position.inMilliseconds / duration.inMilliseconds;
          final isAtEnd = position >= duration;
          
          if ((progress >= 0.9 || isAtEnd) && !_hasNotifiedCompletion) {
            _hasNotifiedCompletion = true;
            
            // Pausar el audio cuando se completa
            if (isAtEnd && _viewModel.isPlaying) {
              _viewModel.pause();
            }
            
            if (widget.onAudioCompleted != null) {
              widget.onAudioCompleted!();
            }
          }
          
          // Si el usuario vuelve a reproducir el audio después de completarlo,
          // permitir que se pueda completar de nuevo (resetear el flag si el audio se reinicia)
          if (_hasNotifiedCompletion && position < duration * 0.5) {
            // Si el audio se reinició (volvió al inicio), permitir completarlo de nuevo
            _hasNotifiedCompletion = false;
          }
        }
      } catch (e) {
        // Error al verificar, continuar
      }
    });
  }

  @override
  void dispose() {
    _completionCheckTimer?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BasePreviewCard(
      isPreview: widget.isPreview,
      typeOfPreviewCard: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: widget.imagePath != null && widget.imagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildImageFromUrl(
                          widget.imagePath!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.audiotrack,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.audioTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.audioDesc != null && widget.audioDesc!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.audioDesc!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            // Controles de audio
            Column(
              children: [
                // Barra de progreso
                if (_viewModel.duration != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Slider(
                          value: _viewModel.position.inMilliseconds.toDouble().clamp(
                            0.0,
                            _viewModel.duration!.inMilliseconds.toDouble(),
                          ),
                          min: 0.0,
                          max: _viewModel.duration!.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _viewModel.seek(Duration(milliseconds: value.toInt()));
                          },
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _viewModel.formatDuration(_viewModel.position),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _viewModel.formatDuration(_viewModel.duration!),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Botones de control
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay, color: Colors.white, size: 28),
                      onPressed: () {
                        _viewModel.replay();
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        _viewModel.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 64,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _viewModel.togglePlayPause();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Helper function para construir imágenes desde URLs
/// Detecta automáticamente si es un asset local o URL externa
/// Permite usar URLs tal cual están en la base de datos sin agregar prefijos automáticos
Widget _buildImageFromUrl(
  String url, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.contain,
}) {
  // Si la URL es una URL externa (http/https), usar Image.network
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // Si es un asset local, usar Image.asset directamente con la URL tal cual está
  // No agregamos "assets/" porque la URL ya viene completa desde la BD
  return Image.asset(
    url,
    height: height,
    width: width,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
  );
}
