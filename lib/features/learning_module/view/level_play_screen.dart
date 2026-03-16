import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../minigames/minigame_core.dart';
import '../../minigames/view/minigames_widget.dart';
import '../../../data/services/firestore_services.dart';
import '../viewmodel/learning_viewmodel.dart';
import '../viewmodel/video_viewmodel.dart';
import '../../avatar/viewmodel/avatar_viewmodel.dart';

/// Pantalla de juego de nivel
/// Se muestra cuando el usuario presiona "JUGAR" en un nivel del timeline
class LevelPlayScreen extends StatefulWidget {
  final String levelTitle;
  final Map<String, dynamic>? minigameData;
  final String? actividadType;
  final String? levelId;
  final String? moduleId;
  /// URL del video (desde Firebase Storage o Firestore) para niveles de tipo 'video'
  final String? videoUrl;
  // Permite abrir seleccion simple de forma explicita al tocar la tarjeta del carrusel.
  final bool launchSimpleSelectionFromCard;

  const LevelPlayScreen({
    super.key,
    required this.levelTitle,
    this.minigameData,
    this.actividadType,
    this.levelId,
    this.moduleId,
    this.videoUrl,
    this.launchSimpleSelectionFromCard = false,
  });

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen> {
  late int _retriesLeft;
  Key _minigameKey = UniqueKey();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _retriesLeft =
        2; // Número de veces que puede reintentar después del primer intento
  }

  /// Reinicia el minigame con opciones mezcladas y intentos reducidos
  void _restartMinigame() {
    if (_retriesLeft > 0) {
      setState(() {
        _retriesLeft--;
        _minigameKey = UniqueKey(); // Esto fuerza la recreación del widget
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.actividadType?.toLowerCase().trim();
    final simpleSelectionEnabled = _isSimpleSelectionEnabled(widget.minigameData);

    // Seleccion simple solo inicia cuando se entra desde la tarjeta del carrusel.
    if (widget.launchSimpleSelectionFromCard && simpleSelectionEnabled) {
      return _buildMinigameScaffold(MinigameType.simpleSelection);
    }

    // Si se intentó abrir desde tarjeta pero no está habilitado, bloquear acceso.
    if (widget.launchSimpleSelectionFromCard && !simpleSelectionEnabled) {
      return _buildUnavailableActivityScreen();
    }

    if (type == null || type.isEmpty) {
      return _buildUnavailableActivityScreen();
    }

    // Manejo especial para niveles de tipo 'video': mostrar reproductor de video
    if (type == 'video') {
      final url = widget.videoUrl ??
          (widget.minigameData?['videoUrl'] as String?) ??
          (widget.minigameData?['url'] as String?);

      if (url == null || url.isEmpty) {
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

      return _LevelVideoPlayerScreen(
        videoUrl: url,
        levelTitle: widget.levelTitle,
        levelId: widget.levelId,
        moduleId: widget.moduleId,
        previewImageUrl: widget.minigameData?['pictogramaUrl'] as String?,
        onCompleted: (success) async {
          if (success) {
            await _saveProgress(context, true, 1);
          }
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    // Para actividades no lanzadas desde tarjeta, se usa actividadType.
    MinigameType? minigameType;
    switch (type) {
      case 'simple_selection':
        minigameType = simpleSelectionEnabled
            ? MinigameType.simpleSelection
            : null;
        break;
      case 'pictogram':
        minigameType = MinigameType.pictogram;
        break;
      case 'audio':
        minigameType = MinigameType.audio;
        break;
      default:
        minigameType = null;
    }

    if (minigameType == null) {
      return _buildUnavailableActivityScreen();
    }

    return _buildMinigameScaffold(minigameType);
  }

  Widget _buildMinigameScaffold(MinigameType minigameType) {
    return Scaffold(
      body: MinigamesWidget(
        key: _minigameKey,
        minigameType: minigameType,
        minigameData: widget.minigameData ?? _getDefaultMinigameData(),
        onComplete: (success, attempts) {
          _handleMinigameComplete(context, success, attempts);
        },
      ),
    );
  }

  Widget _buildUnavailableActivityScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              const Text(
                'Actividad no disponible.',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF091F2C),
    );
  }

  /// Calcula las estrellas basado en los intentos
  /// 1 intento = 3 estrellas, 2 intentos = 2 estrellas, 3+ intentos = 1 estrella
  int _calculateStars(int attempts) {
    if (attempts <= 1) return 3;
    if (attempts == 2) return 2;
    return 1;
  }

  /// Calcula las monedas basado en las estrellas obtenidas
  /// 3 estrellas = 30 monedas, 2 estrellas = 20 monedas, 1 estrella = 10 monedas
  int _calculateCoins(int stars) {
    switch (stars) {
      case 3:
        return 30;
      case 2:
        return 20;
      case 1:
        return 10;
      default:
        return 0;
    }
  }

  /// Guarda el progreso del usuario en Firestore y otorga recompensas
  Future<void> _saveProgress(BuildContext context, bool success, int attempts) async {
    if (widget.levelId == null || widget.moduleId == null) {
      return; // No se puede guardar sin levelId y moduleId
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return; // No hay usuario autenticado
    }

    try {
      final stars = success ? _calculateStars(attempts) : 0;
      
      final progressData = {
        'status': success ? 'completed' : 'in_progress',
        'estrellas': stars,
        'attempts': attempts,
        'completedAt': success ? DateTime.now().toIso8601String() : null,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestoreService.updateUserLevelProgress(
        user.uid,
        widget.moduleId!,
        widget.levelId!,
        progressData,
      );

      // Otorgar monedas si el nivel se completó exitosamente
      if (success && stars > 0 && context.mounted) {
        try {
          final avatarViewModel = context.read<AvatarViewModel>();
          final coins = _calculateCoins(stars);
          await avatarViewModel.agregarMonedas(coins);
        } catch (e) {
          // Error al agregar monedas, pero no bloqueamos la UI
          // Log de error silencioso para no interrumpir la experiencia del usuario
        }
      }

      // Limpiar caché del módulo para forzar recarga
      if (context.mounted) {
        final learningViewModel = context.read<LearningViewModel>();
        await learningViewModel.getModuleLevels(widget.moduleId!, forceReload: true);
      }
    } catch (e) {
      // Error al guardar, pero no bloqueamos la UI
      // Log de error silencioso para no interrumpir la experiencia del usuario
    }
  }

  /// Construye la imagen del pictograma para mostrar en el diálogo
  Widget _buildPictogramImage(Map<String, dynamic> minigameData) {
    final imageUrl = minigameData['pictogramaUrl'] as String?;

    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Construir la imagen según el tipo de URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 250, maxWidth: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x66FFFFFF), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.white54,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              // Skeleton con el mismo color de fondo que el diálogo (azul oscuro),
              // necesario porque el PNG tiene fondo transparente
              return const _PlayScreenShimmer(baseColor: Color(0xFF1A3D52));
            },
          ),
        ),
      );
    } else {
      // Asset local
      return Container(
        constraints: const BoxConstraints(maxHeight: 250, maxWidth: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x66FFFFFF), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.white54,
                ),
              );
            },
          ),
        ),
      );
    }
  }

  /// Maneja la finalización del minijuego
  void _handleMinigameComplete(
    BuildContext context,
    bool success,
    int attempts,
  ) async {
    // Guardar progreso si fue exitoso
    if (success) {
      await _saveProgress(context, success, attempts);
    }
    // Mostrar resultado y navegar de regreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A3D52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x66FFFFFF), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(
              success ? Icons.celebration : Icons.emoji_events_outlined,
              color: success
                  ? const Color(0xFF05E995)
                  : const Color(0xFFFF9800),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success ? '¡Nivel Completado!' : '¡Buen Intento!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mostrar imagen del pictograma si es un minigame de tipo pictogram
            if (widget.actividadType?.toLowerCase().trim() == 'pictogram' &&
                widget.minigameData != null) ...[
              _buildPictogramImage(widget.minigameData!),
              const SizedBox(height: 16),
            ],
            Text(
              success
                  ? '¡Excelente trabajo! Has completado el nivel con éxito.'
                  : _retriesLeft > 0
                  ? 'No te preocupes, puedes intentarlo de nuevo.'
                  : 'Has agotado todos tus reintentos.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33FFFFFF), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Color(0xFFFFD700)),
                      const SizedBox(width: 8),
                      Text(
                        'Intentos: $attempts',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (success) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
                        const SizedBox(width: 8),
                        Text(
                          'Monedas: +${_calculateCoins(_calculateStars(attempts))}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!success && _retriesLeft > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(100, 255, 152, 0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9800), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Reintentos disponibles: $_retriesLeft',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!success)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver al timeline
              },
              child: const Text(
                'Volver',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              if (success) {
                Navigator.of(context).pop(); // Volver al timeline
                // El progreso ya se guardó en _handleMinigameComplete
              } else {
                // Reintentar: reiniciar el minigame con opciones mezcladas
                if (_retriesLeft > 0) {
                  _restartMinigame();
                } else {
                  // Si no quedan reintentos, volver al timeline
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success
                  ? const Color(0xFF05E995)
                  : (_retriesLeft > 0 ? const Color(0xFFFF9800) : Colors.grey),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              success
                  ? 'Continuar'
                  : (_retriesLeft > 0 ? 'Reintentar' : 'Salir'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Datos por defecto del minijuego para testing
  Map<String, dynamic> _getDefaultMinigameData() {
    return {
      'question': 'Selecciona la imagen correcta',
      'correctIndex': 0,
      'maxAttempts': 3,
      'options': [
        {'imagePath': 'assets/images/FELIZ.png', 'label': 'Opción 1'},
        {'imagePath': 'assets/images/TRISTE.png', 'label': 'Opción 2'},
        {'imagePath': 'assets/images/MEH.png', 'label': 'Opción 3'},
      ],
    };
  }

  bool _isSimpleSelectionEnabled(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('isSimpleSelectionEnabled')) {
      return false;
    }
    final value = data['isSimpleSelectionEnabled'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget de reproductor de video para niveles con actividadType == 'video'
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla dedicada al reproductor de video para niveles de tipo 'video'.
/// Muestra el video en pantalla completa con controles y marca el nivel como
/// completado cuando el usuario ha visto al menos el 90% del video.
class _LevelVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String levelTitle;
  final String? levelId;
  final String? moduleId;
  final String? previewImageUrl;
  final void Function(bool success) onCompleted;

  const _LevelVideoPlayerScreen({
    required this.videoUrl,
    required this.levelTitle,
    required this.onCompleted,
    this.levelId,
    this.moduleId,
    this.previewImageUrl,
  });

  @override
  State<_LevelVideoPlayerScreen> createState() =>
      _LevelVideoPlayerScreenState();
}

class _LevelVideoPlayerScreenState extends State<_LevelVideoPlayerScreen> {
  late VideoViewModel _viewModel;
  bool _hasNotifiedCompletion = false;
  bool _isCompleted = false;
  bool _hasStartedPlaying = false;

  @override
  void initState() {
    super.initState();
    _viewModel = VideoViewModel();
    _viewModel.initialize(widget.videoUrl, null);
    _viewModel.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    setState(() {});

    if (_hasNotifiedCompletion) return;

    try {
      final controller = _viewModel.videoController;
      if (!controller.value.isInitialized) return;

      final position = controller.value.position;
      final duration = controller.value.duration;

      if (duration.inMilliseconds <= 0) return;

      final progress = position.inMilliseconds / duration.inMilliseconds;
      final isAtEnd = position >= duration;

      if (progress >= 0.9 || isAtEnd) {
        _hasNotifiedCompletion = true;
        setState(() => _isCompleted = true);
        // Pause when done
        if (controller.value.isPlaying) {
          controller.pause();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onVideoUpdate);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _viewModel.initializeVideoFuture,
          builder: (context, snapshot) {
            final ready = snapshot.connectionState == ConnectionState.done &&
                snapshot.error == null;

            return Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.levelTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Video area ────────────────────────────────────────────────
                Expanded(
                  child: !ready
                      ? (snapshot.connectionState != ConnectionState.done
                          // Skeleton sobre fondo negro mientras el video inicializa
                          ? const _PlayScreenShimmer(baseColor: Colors.black)
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 64),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No se pudo cargar el video.\n${snapshot.error}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ))
                      // ── Ready: show cover until first play, then video ──────
                      : GestureDetector(
                          onTap: () {
                            setState(() => _hasStartedPlaying = true);
                            _viewModel.togglePlayPause();
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            fit: StackFit.expand,
                            children: [
                              Container(color: Colors.black),
                              // Video (always rendered so it buffers in background)
                              Center(
                                child: AspectRatio(
                                  aspectRatio:
                                      _viewModel.videoController.value.aspectRatio,
                                  child: VideoPlayer(_viewModel.videoController),
                                ),
                              ),
                              // Cover image — shown until user first presses play
                              if (!_hasStartedPlaying)
                                Center(
                                  child: AspectRatio(
                                    aspectRatio:
                                        _viewModel.videoController.value.aspectRatio,
                                    child: widget.previewImageUrl != null &&
                                            widget.previewImageUrl!.isNotEmpty
                                        ? Image.network(
                                            widget.previewImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(color: Colors.black),
                                            // Skeleton sobre fondo negro mientras carga la imagen de portada
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const _PlayScreenShimmer(baseColor: Colors.black);
                                            },
                                          )
                                        : Container(color: Colors.black),
                                  ),
                                ),
                              // Play button on cover / play-pause icon during playback
                              if (!_hasStartedPlaying)
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white70,
                                    size: 72,
                                  ),
                                )
                              else
                                AnimatedOpacity(
                                  opacity: _viewModel.showGiantIcon ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      _viewModel.videoController.value.isPlaying
                                          ? 'assets/icons/pausebigbutton.svg'
                                          : 'assets/icons/playbigbutton.svg',
                                      width: 80,
                                      height: 80,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),

                // ── Bottom controls ───────────────────────────────────────────
                if (ready)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    color: const Color(0xCC000000),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        VideoProgressIndicator(
                          _viewModel.videoController,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF00E5FF),
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Controls row — use GestureDetector instead of IconButton
                        // to avoid the 48px minimum touch target enforcing an overflow
                        // on narrow screens.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Replay
                            GestureDetector(
                              onTap: () {
                                _viewModel.replay();
                                setState(() {
                                  _hasStartedPlaying = true;
                                  _hasNotifiedCompletion = false;
                                  _isCompleted = false;
                                });
                              },
                              child: SvgPicture.asset(
                                'assets/icons/replay.svg',
                                width: 28,
                                height: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Play / Pause
                            GestureDetector(
                              onTap: _viewModel.togglePlayPause,
                              child: SvgPicture.asset(
                                _viewModel.videoController.value.isPlaying
                                    ? 'assets/icons/pausebutton.svg'
                                    : 'assets/icons/playbuttoncontroller.svg',
                                width: 36,
                                height: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Time label — Expanded so it takes remaining space
                            // and never pushes the row past the screen edge.
                            Expanded(
                              child: Text(
                                '${_viewModel.formatDuration(_viewModel.videoController.value.position)} / '
                                '${_viewModel.formatDuration(_viewModel.videoController.value.duration)}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // "COMPLETAR" button
                        if (_isCompleted) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onCompleted(true),
                              icon: const Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              label: const Text(
                                'COMPLETAR',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF05E995),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 10,
                                shadowColor: const Color(0x8005E995),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer reutilizable para estados de carga en esta pantalla
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton con shimmer animado para estados de carga de imagen.
/// Recibe [baseColor] como color de fondo opaco del skeleton box,
/// de forma que el ShaderMask siempre tenga superficie sobre la que pintar.
class _PlayScreenShimmer extends StatefulWidget {
  /// Color base del skeleton box. Debe coincidir con el fondo del contenedor
  /// para que el resultado se vea como parte natural del layout.
  final Color baseColor;

  const _PlayScreenShimmer({required this.baseColor});

  @override
  State<_PlayScreenShimmer> createState() => _PlayScreenShimmerState();
}

class _PlayScreenShimmerState extends State<_PlayScreenShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Ciclo de 1.4 segundos que se repite indefinidamente
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // El destello viaja de izquierda (-2) a derecha (+2)
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // El gradiente usa variantes más claras del baseColor para el destello
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.baseColor.withAlpha(180),
                widget.baseColor.withAlpha(120),
                widget.baseColor.withAlpha(180),
                widget.baseColor,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      // Skeleton box opaco: ocupa todo el espacio del widget padre
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: widget.baseColor,
          boxShadow: [
            BoxShadow(
              color: widget.baseColor.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}
