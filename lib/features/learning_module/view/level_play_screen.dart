import 'package:flutter/material.dart';
import '../../minigames/minigame_core.dart';
import '../../minigames/view/minigames_widget.dart';
import '../../../shared/services/tts_service.dart';
import '../../../shared/services/level_completion_service.dart';
import '../../telemetry/model/telemetry_signals.dart';
import '../../telemetry/model/telemetry_enums.dart';

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

  /// Handle opaco de telemetría (null si no hay consentimiento activo).
  final ActivitySessionHandle? telemetryHandle;

  const LevelPlayScreen({
    super.key,
    required this.levelTitle,
    this.minigameData,
    this.actividadType,
    this.levelId,
    this.moduleId,
    this.videoUrl,
    this.launchSimpleSelectionFromCard = false,
    this.telemetryHandle,
  });

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen> {
  late int _retriesLeft;
  Key _minigameKey = UniqueKey();
  final TtsService _ttsService = TtsService();
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _retriesLeft =
        2; // Número de veces que puede reintentar después del primer intento
    _initTts();
  }

  Future<void> _initTts() async {
    final ready = await _ttsService.initializeDefaultEsMx();
    if (!mounted) return;
    setState(() {
      _ttsReady = ready;
    });
  }

  Future<void> _speakCompletionFeedback(bool success) async {
    if (!_ttsReady) return;

    final message = success
        ? 'Nivel completado. Excelente trabajo.'
        : _retriesLeft > 0
        ? 'Buen intento. Puedes intentarlo de nuevo.'
        : 'Buen intento. Has agotado tus reintentos.';
    await _ttsService.speak(message);
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  /// Reinicia el minigame con opciones mezcladas y intentos reducidos
  void _restartMinigame() {
    if (_retriesLeft > 0) {
      // Conservar la misma sesión y acumulados; solo incrementar runCount.
      widget.telemetryHandle?.onStartRetryRun();
      setState(() {
        _retriesLeft--;
        _minigameKey = UniqueKey(); // Esto fuerza la recreación del widget
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.actividadType?.toLowerCase().trim();
    final simpleSelectionEnabled = _isSimpleSelectionEnabled(
      widget.minigameData,
    );

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

    // Los niveles de tipo 'video' nunca llegan aquí: level_content_screen.dart
    // los enruta directo a VideoPlayerScreen (reproductor horizontal con
    // VideoControlRail y su propia telemetría).

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
      case 'puzzle':
        minigameType = MinigameType.puzzle;
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
    final handle = widget.telemetryHandle;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Salir explícito de una actividad ya iniciada sin completar.
        handle?.onAbandon(TerminalReason.userBack);
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: MinigamesWidget(
          key: _minigameKey,
          minigameType: minigameType,
          minigameData: widget.minigameData ?? _getDefaultMinigameData(),
          onReady: () => handle?.onActivityReady(),
          onObjectiveMet: () => handle?.onObjectiveMet(),
          onComplete: (success, attempts) {
            _handleMinigameComplete(context, success, attempts);
          },
        ),
      ),
    );
  }

  Widget _buildUnavailableActivityScreen() {
    // Actividad no disponible: nunca llega a `started` → launch_error.
    widget.telemetryHandle?.onLaunchError(TerminalReason.activityUnavailable);
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
    final handle = widget.telemetryHandle;
    if (handle != null) {
      final tipo = widget.actividadType?.toLowerCase().trim();
      if (tipo == 'simple_selection' || tipo == 'puzzle') {
        // El resultado del run registra intentos una sola vez; el servicio
        // decide si continúa o termina (el objetivo ya detuvo el reloj).
        handle.onRecordAttempts(attempts);
        if (success) {
          handle.onComplete();
        } else if (_retriesLeft <= 0) {
          handle.onFail();
        }
      } else if (success) {
        // Observación/media: objectiveMet ya emitido; completar.
        handle.onComplete();
      }
    }

    final tipo = widget.actividadType?.toLowerCase().trim();
    final isObservation = tipo == 'pictogram' || tipo == 'video';

    // Guardar progreso: los niveles de observación (pictograma/video) no
    // tienen intentos ni pueden fallar, así que se completan por la vía de
    // observación. Los niveles interactivos siempre escriben su documento de
    // progreso, incluso al fallar, para que el timeline lo registre.
    LevelCompletionResult? result;
    if (isObservation) {
      if (success) {
        result = await LevelCompletionService.completeObservationLevel(
          context: context,
          moduleId: widget.moduleId,
          levelId: widget.levelId,
          actividadType: tipo,
        );
      }
    } else {
      result = await LevelCompletionService.completeInteractiveLevel(
        context: context,
        moduleId: widget.moduleId,
        levelId: widget.levelId,
        actividadType: tipo,
        success: success,
        attempts: attempts,
      );
    }

    await _speakCompletionFeedback(success);
    if (!mounted) return;

    final coins = result?.coins ?? 0;
    final felicidadDelta = result?.felicidadDelta ?? 0;
    final energiaDelta = result?.energiaDelta ?? 0;

    // Mostrar resultado y navegar de regreso
    showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Monedas: +$coins',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                  for (final row in LevelCompletionService.buildStatRows(
                    felicidadDelta,
                    energiaDelta,
                  )) ...[
                    const SizedBox(height: 8),
                    row,
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
                        fontSize: 15,
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
                _ttsService.stop();
                // Hay reintentos disponibles pero el usuario elige Volver → abandon.
                widget.telemetryHandle?.onAbandon(TerminalReason.userExit);
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
              _ttsService.stop();
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
