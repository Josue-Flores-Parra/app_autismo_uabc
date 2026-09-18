import 'dart:async';
import 'dart:math' as math;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../minigame_core.dart';
import '../../../../shared/services/celebration_helper.dart';
import '../../../../shared/services/negative_feedback_helper.dart';
import '../../../../shared/widgets/loading_screen.dart';

class PuzzleMinigame extends MinigameBase {
  const PuzzleMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
    super.onReady,
    super.onObjectiveMet,
  });

  // Crea el estado del minijuego de rompecabezas.
  @override
  State<PuzzleMinigame> createState() => _PuzzleMinigameState();
}

class _PuzzleMinigameState extends State<PuzzleMinigame> {
  late final int _gridSize;
  static const double _knobRatio = 0.15;
  static const Duration _feedbackDuration = Duration(seconds: 3);
  static const Duration _celebrationDuration = Duration(milliseconds: 1500);
  static const double _minTraySize = 0.14;
  static const double _maxTraySize = 0.5;
  static const double _initialTraySize = 0.18;
  static const double _trayHeaderHeight = 78;
  static const Color _feedbackCorrectColor = Color(0xFF00FF7A);
  static const Color _feedbackIncorrectColor = Color(0xFFFF1744);

  late final String _imagePath;
  late final int _maxAttempts;
  late List<int?> _gridSlots;
  late Set<int> _trayPieces;
  late List<_JigsawShape> _pieceShapes;
  final List<int> _trayOrder = <int>[];
  final math.Random _random = math.Random();
  final Set<int> _lockedPieces = <int>{};
  final Map<int, bool> _feedbackSlots = <int, bool>{};
  final DraggableScrollableController _trayController =
      DraggableScrollableController();
  final CelebrationHelper _celebrationHelper = CelebrationHelper();
  //duration: _celebrationDuration,
  //);
  final AudioPlayer _placeSoundPlayer = AudioPlayer();
  // Servicio reutilizable que reproduce el sonido de fallo (negative beep).
  final NegativeFeedbackHelper _negativeFeedbackHelper =
      NegativeFeedbackHelper();

  int _attempts = 0;
  // Intentos restantes antes de fallar el rompecabezas. Se inicializa con
  // _maxAttempts y se decrementa en cada "COMPROBAR" con piezas incorrectas.
  late int _remainingAttempts;
  bool _isCompleted = false;
  bool _isChecking = false;
  bool _isTrayHovering = false;
  double _trayExtent = _initialTraySize;
  bool _isImageReady = false;
  bool _hasImage = true;
  bool _isPreviewExpanded = false;

  bool get _isTrayOpen => _trayExtent >= ((_minTraySize + _maxTraySize) / 2);

  bool get _isGridFull => _gridSlots.every((slot) => slot != null);

  // Inicializa datos, piezas y precarga la imagen.
  @override
  void initState() {
    super.initState();
    _imagePath = _resolveImagePath(widget.minigameData);
    _hasImage = _imagePath.isNotEmpty;
    _gridSize = _resolveGridSize(widget.minigameData);
    _maxAttempts = _resolveMaxAttempts(_gridSize);
    // Los intentos restantes arrancan en el máximo según la dificultad.
    _remainingAttempts = _maxAttempts;
    _gridSlots = List<int?>.filled(_gridSize * _gridSize, null);
    _trayPieces = Set<int>.from(
      List<int>.generate(_gridSize * _gridSize, (index) => index),
    );
    _pieceShapes = _buildPieceShapes();
    _syncTrayOrder(shuffle: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precachePuzzleImage();
      // Imagen, grid, bandeja y dificultad ya están resueltos.
      widget.onReady?.call();
    });
  }

  // Libera recursos del efecto de celebración.
  @override
  void dispose() {
    _celebrationHelper.dispose();
    _placeSoundPlayer.dispose();
    _negativeFeedbackHelper.dispose();
    super.dispose();
  }

  // Sincroniza el orden visual de las piezas en la bandeja.
  void _syncTrayOrder({bool shuffle = false}) {
    _trayOrder
      ..clear()
      ..addAll(_trayPieces);
    if (shuffle) {
      _trayOrder.shuffle(_random);
    }
  }

  // Quita una pieza de la bandeja.
  void _removeFromTray(int pieceId) {
    _trayPieces.remove(pieceId);
    _trayOrder.remove(pieceId);
  }

  // Agrega una pieza a la bandeja (opcionalmente mezclando el orden).
  void _addToTray(int pieceId, {bool shuffle = false}) {
    final added = _trayPieces.add(pieceId);
    if (added) {
      _trayOrder.add(pieceId);
    }
    if (shuffle) {
      _trayOrder.shuffle(_random);
    }
  }

  // Precarga la imagen para evitar parpadeos al renderizar piezas.
  Future<void> _precachePuzzleImage() async {
    if (!_hasImage) {
      if (!mounted) return;
      setState(() {
        _isImageReady = true;
      });
      return;
    }
    try {
      // intentar iniciar el precaching
      await precacheImage(_imageProvider(), context);
    } catch (_) {
      // Ignorar errores de precache para no bloquear el juego.
    } finally {
      if (!mounted) return;
      setState(() {
        _isImageReady = true;
      });
    }
  }

  // Resuelve la ruta/URL de la imagen del rompecabezas.
  String _resolveImagePath(Map<String, dynamic> data) {
    final puzzleUrl = data['puzzleImageUrl']?.toString().trim();
    if (puzzleUrl != null && puzzleUrl.isNotEmpty) {
      return puzzleUrl;
    }
    final fallbackUrl = data['pictogramaUrl']?.toString().trim();
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      return fallbackUrl;
    }
    final legacy = (data['imageUrl'] ?? data['imagePath'])?.toString().trim();
    if (legacy != null && legacy.isNotEmpty) {
      return legacy;
    }
    return '';
  }

  // Resuelve el número máximo de intentos a partir de la dificultad (gridSize).
  // La dificultad la elige el usuario en el diálogo previo al minijuego:
  //   Fácil (gridSize 4)  -> 5 intentos
  //   Normal (gridSize 5) -> 4 intentos
  //   Difícil (gridSize 6)-> 3 intentos
  // El valor de `maxAttempts` del mapa de datos se ignora a propósito: los
  // intentos derivan exclusivamente de la dificultad seleccionada.
  int _resolveMaxAttempts(int gridSize) {
    switch (gridSize) {
      case 2:
        return 6; // Muy facil
      case 3:
        return 5; // Fácil
      case 4:
        return 4; // Normal
      case 5:
        return 3; // Difícil
      default:
        return 999; // Fallback (gridSize heredado) → sin límite.
    }
  }

  // Resuelve el tamaño de la cuadrícula según la dificultad elegida.
  int _resolveGridSize(Map<String, dynamic> data) {
    final value = data['gridSize'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 3;
    return 3;
  }

  // Alterna la bandeja entre abierta y cerrada.
  void _toggleTray() {
    if (_isChecking) return;
    final target = _isTrayOpen ? _minTraySize : _maxTraySize;
    _trayController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  // Cierra la bandeja si está abierta.
  void _closeTray() {
    if (!_isTrayOpen) return;
    _trayController.animateTo(
      _minTraySize,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  // Obtiene el ImageProvider según sea asset o URL remota.
  ImageProvider _imageProvider() {
    if (_imagePath.startsWith('http://') || _imagePath.startsWith('https://')) {
      return NetworkImage(_imagePath);
    }
    return AssetImage(_imagePath);
  }

  Alignment _alignmentForPiece(int pieceId, double baseSize, {double knobRatio = _knobRatio}) {
    // Convierte la posición de la pieza en la cuadrícula al espacio de alineación del OverflowBox.
    final row = pieceId ~/ _gridSize; // División entera para obtener la fila.
    final col = pieceId % _gridSize; // Módulo para obtener la columna.

    // Calcula el offset ideal en pixeles para que la celda base quede alineada bajo el clip.
    // Y evitar que las pestañas/encajes se distorsionen al recortar la imagen.
    final imageSize = baseSize * _gridSize;
    final pieceExtent = baseSize * (1 + (knobRatio * 2));
    final knobSize = baseSize * knobRatio;
    final desiredOffsetX = knobSize - (col * baseSize);
    final desiredOffsetY = knobSize - (row * baseSize);

    // Convierte el offset en pixeles al rango [-1, 1] de Alignment.
    // El centro de la imagen es (0, 0), el borde izquierdo es -1 y el derecho es 1. Lo mismo para vertical.
    double toAlignment(double desiredOffset) {
      final denominator = pieceExtent - imageSize;
      if (denominator == 0) return 0;
      return (2 * desiredOffset / denominator) - 1;
    }

    // El resultado es un Alignment que posiciona la imagen dentro del OverflowBox de manera que la celda base de la pieza quede correctamente recortada, incluso con las pestañas/encajes.
    return Alignment(toAlignment(desiredOffsetX), toAlignment(desiredOffsetY));
  }

  // Alineación lineal para piezas "solo celda" (bandeja con cuadrícula pequeña):
  // la celda base llena exactamente el marco, mostrando 1/N de la imagen sin
  // contenido de los vecinos — cada pieza se ve como una división limpia, sin
  // "sangrar" hacia las adyacentes.
  Alignment _alignmentForCell(int pieceId) {
    final row = pieceId ~/ _gridSize;
    final col = pieceId % _gridSize;
    return Alignment(
      (2 * col / (_gridSize - 1)) - 1,
      (2 * row / (_gridSize - 1)) - 1,
    );
  }

  // Construye el fragmento visual recortado de la imagen.
  Widget _buildPieceImage(
    int pieceId,
    double baseSize, {
    bool onlyCell = false,
    double knobRatio = _knobRatio,
  }) {
    // Tamaño total de la imagen del rompecabezas según el tamaño base de una pieza.
    final imageSize = baseSize * _gridSize;
    // Tamaño expandido para incluir las pestañas/encajes alrededor de la celda base.
    final pieceExtent = baseSize * (1 + (knobRatio * 2));
    // En modo "solo celda" el marco es exactamente el de la celda
    // (sin margen de
    // pestañas), así la pieza muestra únicamente su celda y no a sus vecinas.
    final windowSize = onlyCell ? baseSize : pieceExtent;

    return SizedBox(
      width: windowSize,
      height: windowSize,
      child: OverflowBox(
        maxWidth: imageSize,
        maxHeight: imageSize,
        alignment: onlyCell
            ? _alignmentForCell(pieceId)
            : _alignmentForPiece(pieceId, baseSize, knobRatio: knobRatio),
        child: Image(
          image: _imageProvider(),
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0x332C5F7A)),
        ),
      ),
    );
  }

  Widget _buildPieceSurface(
    int pieceId, {
    required _JigsawShape shape,
    required double baseSize,
    required Color borderColor,
    double borderWidth = 1.2,
    Color? shadowColor,
    bool onlyCell = false,
    double knobRatio = _knobRatio,
  }) {
    if (onlyCell) {
      // Pieza "solo celda": se muestra únicamente el contenido de la celda, sin
      // pestañas/encajes, recortando cualquier desbordamiento de la imagen.
      return Container(
        width: baseSize,
        height: baseSize,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _buildPieceImage(pieceId, baseSize, onlyCell: true, knobRatio: knobRatio),
        ),
      );
    }

    // Amplía el contenedor para mostrar las pestañas/encajes fuera de la celda base.
    final pieceExtent = baseSize * (1 + (knobRatio * 2));
    // Tamaño físico de la pestaña usado por el clipper/painter.
    final knobSize = baseSize * knobRatio;

    return SizedBox(
      width: pieceExtent,
      height: pieceExtent,
      child: CustomPaint(
        painter: _JigsawBorderPainter(
          shape: shape,
          knobSize: knobSize,
          borderColor: borderColor,
          borderWidth: borderWidth,
          shadowColor: shadowColor,
        ),
        child: ClipPath(
          clipper: _JigsawClipper(shape: shape, knobSize: knobSize),
          child: _buildPieceImage(pieceId, baseSize, knobRatio: knobRatio),
        ),
      ),
    );
  }

  // Crea una pieza draggable desde bandeja o cuadrícula.
  Widget _buildDraggablePiece(
    int pieceId, {
    int? fromSlot,
    double size = 56,
    bool onlyCell = false,
    double knobRatio = _knobRatio,
  }) {
    final shape = _pieceShapes[pieceId];
    final piece = _buildPieceSurface(
      pieceId,
      shape: shape,
      baseSize: size,
      borderColor: const Color(0xCCFFFFFF),
      shadowColor: const Color(0x55000000),
      onlyCell: onlyCell,
      knobRatio: knobRatio,
    );

    // El Draggable envuelve la pieza para permitir arrastrarla, proporcionando feedback
    // visual durante el arrastre y manejando el estado de la pieza en la bandeja o cuadrícula.
    return Draggable<_PuzzleDragData>(
      data: _PuzzleDragData(pieceId: pieceId, fromSlot: fromSlot),
      feedback: Material(
        color: Colors.transparent,
        child: _buildPieceSurface(
          pieceId,
          shape: shape,
          baseSize: size,
          borderColor: const Color(0xFF00E5FF),
          borderWidth: 2,
          shadowColor: const Color(0xAA000000),
          onlyCell: onlyCell,
          knobRatio: knobRatio,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: piece),
      onDragStarted: () {
        // Si la pieza viene de la cuadrícula, se libera el espacio para permitir que otros la ocupen visualmente.
        if (fromSlot == null) {
          _closeTray();
        }
      },
      child: piece,
    );
  }

  // Maneja cuando una pieza se suelta en una celda de la cuadrícula.
  void _handleGridAccept(int slotIndex, _PuzzleDragData data) {
    if (_isChecking) return; // No permitir mover piezas durante la validación.
    if (_gridSlots[slotIndex] != null)
      return; // Protección extra, aunque DragTarget ya lo previene.

    setState(() {
      // Si la pieza viene de otra celda, se libera esa celda. Si viene de la bandeja, se elimina de la bandeja.
      if (data.fromSlot != null) {
        _gridSlots[data.fromSlot!] = null;
      } else {
        _removeFromTray(data.pieceId);
        _closeTray();
      }
      _gridSlots[slotIndex] = data.pieceId;
      _feedbackSlots.remove(slotIndex);
    });

    _playPlaceSound();
  }

  // Maneja cuando una pieza se devuelve a la bandeja.
  void _handleTrayAccept(_PuzzleDragData data) {
    if (_isChecking)
      return; // No permitir devolver piezas durante la validación.
    setState(() {
      // Si la pieza viene de una celda, se libera esa celda. Si viene de la bandeja, no hay nada que liberar.
      if (data.fromSlot != null) {
        _gridSlots[data.fromSlot!] = null;
      }
      _addToTray(data.pieceId, shuffle: true);
      _feedbackSlots.remove(data.fromSlot);
    });
  }

  // Configura la sesión de audio para reproducir sonidos de feedback.
  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (_) {}
  }

  // Reproduce el sonido de feedback al colocar una pieza en la cuadrícula.
  Future<void> _playPlaceSound() async {
    try {
      await _configureAudioSession();
      await _placeSoundPlayer.setAudioSource(
        AudioSource.asset('assets/audio/puzzle_piece_placed.mp3'),
      );
      await _placeSoundPlayer.setVolume(1.0);
      if (_placeSoundPlayer.processingState == ProcessingState.loading) {
        await _placeSoundPlayer.playerStateStream
            .timeout(const Duration(seconds: 3))
            .firstWhere(
              (state) => state.processingState != ProcessingState.loading,
            );
      }
      await _placeSoundPlayer.play();
    } catch (_) {}
  }

  // Valida el tablero, muestra feedback y procesa el resultado.
  Future<void> _checkPuzzle() async {
    if (_isChecking || _isCompleted || !_isGridFull) return;

    final correctSlots = <int>{};
    final incorrectSlots = <int>{};
    // Comparar cada celda con su pieza correcta (que coincide con el índice).
    for (int i = 0; i < _gridSlots.length; i++) {
      final pieceId = _gridSlots[i];
      if (pieceId == null) continue;
      // La pieza se agrega a las correctas o incorrectas según si su ID coincide con el índice de la celda.
      if (pieceId == i) {
        correctSlots.add(i);
      } else {
        incorrectSlots.add(i);
      }
    }

    setState(() {
      _attempts++;
      // Solo se consume un intento cuando el tablero NO es correcto. Un
      // "COMPROBAR" acertado no reduce los intentos restantes.
      if (incorrectSlots.isNotEmpty) {
        _remainingAttempts--;
      }
      _isChecking = true;
      // Actualizar el feedback para cada celda: verde para correcto, rojo para incorrecto.
      _feedbackSlots
        ..clear()
        ..addEntries(correctSlots.map((slot) => MapEntry(slot, true)))
        ..addEntries(incorrectSlots.map((slot) => MapEntry(slot, false)));
      for (final slot in correctSlots) {
        final pieceId = _gridSlots[slot];
        if (pieceId != null) {
          _lockedPieces.add(pieceId);
        }
      }
    });
    // Si no hay celdas incorrectas, el rompecabezas está completo.
    if (incorrectSlots.isEmpty) {
      // Señal de objetivo inmediatamente antes de la celebración/delay.
      widget.onObjectiveMet?.call();
      setState(() {
        _isCompleted = true;
        _isChecking = false;
        _feedbackSlots.clear();
      });
      // Reproducir celebración, esperar su duración y luego llamar al callback de finalización con éxito.
      await _celebrationHelper.playCelebration();
      await Future<void>.delayed(_celebrationDuration);
      if (!mounted) return;
      widget.onComplete(true, _attempts);
      return;
    }
    // Si hay celdas incorrectas, se muestra el feedback durante un tiempo y luego se devuelven las piezas incorrectas a la bandeja, limpiando el feedback.
    // Si se alcanzó el número máximo de intentos, se marca como completado sin éxito.
    await Future<void>.delayed(_feedbackDuration);
    if (!mounted) return;
    // Después de mostrar el feedback, las piezas incorrectas se devuelven a la bandeja y se limpian los estados de feedback.
    // Si se alcanzó el número máximo de intentos, se marca como completado sin éxito.
    setState(() {
      for (final slot in incorrectSlots) {
        final pieceId = _gridSlots[slot];
        if (pieceId != null) {
          _addToTray(
            pieceId,
            shuffle: false,
          ); // Devolver a bandeja sin mezclar para que el jugador pueda encontrarla fácilmente.
        }
        _gridSlots[slot] = null;
      }
      _trayOrder.shuffle(_random);
      _feedbackSlots.clear();
      _isChecking = false;
    });

    // Si los intentos restantes se agotaron, el juego termina sin éxito:
    // reproduce el sonido de fallo (negative beep) y espera un instante antes
    // de notificar el resultado para que el feedback sea perceptible.
    if (_remainingAttempts <= 0 && !_isCompleted) {
      setState(() {
        _isCompleted = true;
      });
      _negativeFeedbackHelper.playNegativeBeep();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      widget.onComplete(false, _attempts);
    }
  }

  // Construye el encabezado con título e instrucción.
  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.only(left: 20, right: 8, top: 16, bottom: 16),
      // padding derecho reducido para dar espacio a la imagen del preview, sin que estorbe al titulo/instrucciones
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x4DFFFFFF), width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Rompecabezas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Arrastra las piezas para completar la imagen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                // Indicador de intentos restantes, alimentado por _remainingAttempts.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag, color: Color(0xFFFFD700), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Intentos: $_remainingAttempts',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildPreview(),
        ],
      ),
    );
  }

  // Mantiene compatibilidad; la instrucción ya está en el encabezado.
  Widget _buildInstruction() {
    return const SizedBox.shrink();
  }

  // Miniatura de referencia que muestra el resultado final del rompecabezas.
  Widget _buildPreview() {
    if (!_hasImage) return const SizedBox(width: 56);
    return GestureDetector(
      onTap: () => setState(() => _isPreviewExpanded = true),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x99FFFFFF), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image(
            image: _imageProvider(),
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0x332C5F7A)),
          ),
        ),
      ),
    );
  }

  // Vista ampliada de la imagen de referencia; se cierra al tocar en cualquier parte.
  Widget _buildExpandedPreview(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isPreviewExpanded = false),
        child: Container(
          color: const Color(0xB3000000),
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: size.height * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image(
                  image: _imageProvider(),
                  width: size.width * 0.8, // 80% del ancho la pantalla
                  height: size.height * 0.5, // 50% del alto de la pantalla
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0x332C5F7A)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _isPreviewExpanded = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF92C5BC),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0x80000000),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye la cuadrícula del rompecabezas con drag targets.
  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mantiene el tablero cuadrado usando la dimensión más pequeña disponible.
        final rawSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final size = rawSize.clamp(240.0, 560.0);
        // Tamaño base de cada celda antes de sumar la expansión por pestañas.
        final slotSize = size / _gridSize;
        return SizedBox(
          width: size,
          height: size,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
            ),
            itemCount: _gridSlots.length,
            itemBuilder: (context, index) {
              final pieceId = _gridSlots[index];
              final feedback = _feedbackSlots[index];
              final isLocked =
                  pieceId != null && _lockedPieces.contains(pieceId);

              return DragTarget<_PuzzleDragData>(
                onWillAcceptWithDetails: (details) {
                  final data = details.data;
                  if (_isChecking || data == null) return false;
                  if (_gridSlots[index] != null) return false;
                  if (data.fromSlot == index) return false;
                  return true;
                },
                onAcceptWithDetails: (details) =>
                    _handleGridAccept(index, details.data),
                builder: (context, candidateData, rejectedData) {
                  final highlight = candidateData.isNotEmpty;
                  final borderColor = feedback == null
                      ? (highlight
                            ? const Color(0xFF00E5FF)
                            : const Color(0x66FFFFFF))
                      : (feedback
                            ? _feedbackCorrectColor
                            : _feedbackIncorrectColor);
                  final glowColor = feedback == null
                      ? Colors.transparent
                      : (feedback
                            ? _feedbackCorrectColor
                            : _feedbackIncorrectColor);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0x332C5F7A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 2.2),
                      boxShadow: [
                        if (feedback != null)
                          BoxShadow(
                            color: glowColor.withAlpha(220),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: pieceId == null
                        ? const SizedBox.shrink()
                        : OverflowBox(
                            // Permite que las pestañas/encajes sobresalgan del área de la celda.
                            maxWidth: slotSize * (1 + (_knobRatio * 2)),
                            maxHeight: slotSize * (1 + (_knobRatio * 2)),
                            alignment: Alignment.center,
                            child: isLocked
                                ? _buildPieceSurface(
                                    pieceId,
                                    shape: _pieceShapes[pieceId],
                                    baseSize: slotSize,
                                    borderColor: const Color(0xCCFFFFFF),
                                    shadowColor: const Color(0x55000000),
                                  )
                                : _buildDraggablePiece(
                                    pieceId,
                                    fromSlot: index,
                                    size: slotSize,
                                  ),
                          ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // Construye el botón para comprobar el resultado.
  Widget _buildCheckButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: !_isGridFull || _isChecking
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkPuzzle,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'COMPROBAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05E995),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0x8005E995),
                  ),
                ),
              ),
            ),
    );
  }

  // Construye el encabezado de la bandeja con arrastre.
  Widget _buildTrayHeader(double screenHeight) {
    return GestureDetector(
      onTap: _toggleTray,
      onVerticalDragUpdate: (details) =>
          _handleTrayDragUpdate(details, screenHeight),
      onVerticalDragEnd: (_) => _handleTrayDragEnd(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _trayHeaderHeight,
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        color: const Color(0xFF1A3D52),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0x66FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedRotation(
              turns: _isTrayOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white70,
                size: 26,
              ),
            ),
            const Text(
              'Piezas',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construye la bandeja inferior con piezas disponibles.
  Widget _buildTray() {
    final trayBorderColor = _isTrayHovering
        ? const Color(0xFF00E5FF)
        : const Color(0x55FFFFFF);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() {
          _trayExtent = notification.extent;
        });
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _trayController,
        minChildSize: _minTraySize,
        maxChildSize: _maxTraySize,
        initialChildSize: _initialTraySize,
        snap: true,
        snapSizes: const [_minTraySize, _maxTraySize],
        builder: (context, scrollController) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          return DragTarget<_PuzzleDragData>(
            onWillAcceptWithDetails: (details) {
              final data = details.data;
              if (_isChecking || data == null) return false;
              setState(() {
                _isTrayHovering = true;
              });
              _trayController.animateTo(
                _maxTraySize,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              );
              return true;
            },
            onAcceptWithDetails: (details) {
              _handleTrayAccept(details.data);
              setState(() {
                _isTrayHovering = false;
              });
            },
            onLeave: (_) {
              setState(() {
                _isTrayHovering = false;
              });
            },
            builder: (context, candidateData, rejectedData) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3D52),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(color: trayBorderColor, width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x99000000),
                        blurRadius: 18,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      if (!_isTrayOpen &&
                          scrollController.hasClients &&
                          scrollController.offset > 0) {
                        scrollController.jumpTo(0);
                      }
                      return false;
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: _trayHeaderHeight,
                            ),
                            child: CustomScrollView(
                              controller: scrollController,
                              physics: const ClampingScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: _gridSize,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final pieceId = _trayOrder[index];
                                      // Se usa LayoutBuilder para leer el tamaño
                                      // real que el SliverGrid asigna a la celda
                                      // (constraints tight). Pasar ese valor como
                                      // baseSize garantiza que la alineación de la
                                      // imagen sea correcta y las pestañas jigsaw
                                      // se dibujen con las proporciones adecuadas
                                      // para cualquier gridSize, incluido 3.
                                      return LayoutBuilder(
                                        builder: (context, constraints) {
                                          final cellSize =
                                              constraints.maxWidth > 0
                                                  ? constraints.maxWidth
                                                  : 64.0;
                                          // Las pestañas se escalan con la celda;
                                          // se usa un knobRatio reducido para que
                                          // luzcan más planas en la bandeja.
                                          return _buildDraggablePiece(
                                            pieceId,
                                            size: cellSize,
                                            knobRatio: 0.08, // 0.08 para evitar que la pestaña corten mucha imagen
                                          );
                                        },
                                      );
                                    }, childCount: _trayOrder.length),
                                  ),
                                ),
                                if (_trayOrder.isEmpty)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Text(
                                        'No hay piezas disponibles.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0x99FFFFFF),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: _buildTrayHeader(screenHeight),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Renderiza la pantalla completa del minijuego.
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final trayOffset = (_trayExtent * screenHeight) + 12;
    final body = !_hasImage
        ? const Center(
            child: Text(
              'Imagen no disponible para este rompecabezas',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          )
        : Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: _isChecking,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final topPadding = constraints.maxHeight * 0.08;
                          return Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: topPadding,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: _buildGrid(context),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * _minTraySize),
                ],
              ),
              if (_isTrayOpen)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleTray,
                  ),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: trayOffset,
                child: _buildCheckButton(),
              ),
              Align(alignment: Alignment.bottomCenter, child: _buildTray()),
              CelebrationHelper.buildTopConfettiOverlay(
                controller: _celebrationHelper.confettiController,
              ),
              if (_isPreviewExpanded) _buildExpandedPreview(context),
            ],
          );

    return Scaffold(
      backgroundColor: const Color(0xFF091F2C),
      body: LoadingOverlay(
        isLoading: _hasImage && !_isImageReady,
        child: SafeArea(child: body),
      ),
    );
  }

  // Ajusta la bandeja al ancla más cercana.
  void _snapTrayToClosest() {
    final target = _isTrayOpen ? _maxTraySize : _minTraySize;
    _trayController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  // Actualiza el tamaño de la bandeja durante el arrastre.
  void _handleTrayDragUpdate(DragUpdateDetails details, double screenHeight) {
    if (_isChecking) return;
    final delta = details.primaryDelta ?? 0;
    final nextExtent = (_trayExtent - (delta / screenHeight)).clamp(
      _minTraySize,
      _maxTraySize,
    );
    _trayController.jumpTo(nextExtent);
  }

  // Finaliza el arrastre y aplica el snap.
  void _handleTrayDragEnd() {
    if (_isChecking) return;
    _snapTrayToClosest();
  }

  List<_JigsawShape> _buildPieceShapes() {
    final shapes = List<_JigsawShape>.filled(
      _gridSize * _gridSize,
      const _JigsawShape.empty(),
    );

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        final index = row * _gridSize + col;
        final top = row == 0
            ? _EdgeType.flat
            : shapes[(row - 1) * _gridSize + col].bottom.inverted;
        final left = col == 0
            ? _EdgeType.flat
            : shapes[row * _gridSize + (col - 1)].right.inverted;
        final right = col == _gridSize - 1
            ? _EdgeType.flat
            : _randomEdgeType(_random);
        final bottom = row == _gridSize - 1
            ? _EdgeType.flat
            : _randomEdgeType(_random);

        shapes[index] = _JigsawShape(
          top: top,
          right: right,
          bottom: bottom,
          left: left,
        );
      }
    }

    return shapes;
  }
}

class _PuzzleDragData {
  final int pieceId;
  final int? fromSlot;

  // Datos del drag: pieza y origen en la cuadrícula.
  const _PuzzleDragData({required this.pieceId, required this.fromSlot});
}

// Registra el minijuego de rompecabezas en el factory.
void registerPuzzleMinigame() {
  MinigameFactory.register(
    MinigameType.puzzle,
    ({required onComplete, required minigameData, onReady, onObjectiveMet}) =>
        PuzzleMinigame(
          onComplete: onComplete,
          minigameData: minigameData,
          onReady: onReady,
          onObjectiveMet: onObjectiveMet,
        ),
  );
}

enum _EdgeType { flat, tab, slot }

extension on _EdgeType {
  _EdgeType get inverted {
    switch (this) {
      case _EdgeType.flat:
        return _EdgeType.flat;
      case _EdgeType.tab:
        return _EdgeType.slot;
      case _EdgeType.slot:
        return _EdgeType.tab;
    }
  }
}

_EdgeType _randomEdgeType(math.Random random) {
  return random.nextBool() ? _EdgeType.tab : _EdgeType.slot;
}

class _JigsawShape {
  final _EdgeType top;
  final _EdgeType right;
  final _EdgeType bottom;
  final _EdgeType left;

  const _JigsawShape({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  const _JigsawShape.empty()
    : top = _EdgeType.flat,
      right = _EdgeType.flat,
      bottom = _EdgeType.flat,
      left = _EdgeType.flat;
}

class _JigsawClipper extends CustomClipper<Path> {
  final _JigsawShape shape;
  final double knobSize;

  const _JigsawClipper({required this.shape, required this.knobSize});

  @override
  Path getClip(Size size) {
    // Cuadrado base sin contar el margen de las pestañas en cada lado.
    final base = size.width - (knobSize * 2);
    final x0 = knobSize;
    final y0 = knobSize;

    final path = Path()..moveTo(x0, y0);
    _drawTop(path, x0, y0, base);
    _drawRight(path, x0, y0, base);
    _drawBottom(path, x0, y0, base);
    _drawLeft(path, x0, y0, base);
    path.close();
    return path;
  }

  void _drawTop(Path path, double x, double y, double base) {
    if (shape.top == _EdgeType.flat) {
      path.lineTo(x + base, y);
      return;
    }
    // La dirección invierte la curva: pestaña hacia afuera o encaje hacia adentro.
    final direction = shape.top == _EdgeType.tab ? -1.0 : 1.0;
    path.lineTo(x + base * 0.25, y);
    path.cubicTo(
      x + base * 0.25,
      y + direction * knobSize * 0.2,
      x + base * 0.35,
      y + direction * knobSize,
      x + base * 0.5,
      y + direction * knobSize,
    );
    path.cubicTo(
      x + base * 0.65,
      y + direction * knobSize,
      x + base * 0.75,
      y + direction * knobSize * 0.2,
      x + base * 0.75,
      y,
    );
    path.lineTo(x + base, y);
  }

  void _drawRight(Path path, double x, double y, double base) {
    if (shape.right == _EdgeType.flat) {
      path.lineTo(x + base, y + base);
      return;
    }
    // La dirección invierte la curva: pestaña hacia afuera o encaje hacia adentro.
    final direction = shape.right == _EdgeType.tab ? 1.0 : -1.0;
    path.lineTo(x + base, y + base * 0.25);
    path.cubicTo(
      x + base + direction * knobSize * 0.2,
      y + base * 0.25,
      x + base + direction * knobSize,
      y + base * 0.35,
      x + base + direction * knobSize,
      y + base * 0.5,
    );
    path.cubicTo(
      x + base + direction * knobSize,
      y + base * 0.65,
      x + base + direction * knobSize * 0.2,
      y + base * 0.75,
      x + base,
      y + base * 0.75,
    );
    path.lineTo(x + base, y + base);
  }

  void _drawBottom(Path path, double x, double y, double base) {
    if (shape.bottom == _EdgeType.flat) {
      path.lineTo(x, y + base);
      return;
    }
    // La dirección invierte la curva: pestaña hacia afuera o encaje hacia adentro.
    final direction = shape.bottom == _EdgeType.tab ? 1.0 : -1.0;
    path.lineTo(x + base * 0.75, y + base);
    path.cubicTo(
      x + base * 0.75,
      y + base + direction * knobSize * 0.2,
      x + base * 0.65,
      y + base + direction * knobSize,
      x + base * 0.5,
      y + base + direction * knobSize,
    );
    path.cubicTo(
      x + base * 0.35,
      y + base + direction * knobSize,
      x + base * 0.25,
      y + base + direction * knobSize * 0.2,
      x + base * 0.25,
      y + base,
    );
    path.lineTo(x, y + base);
  }

  void _drawLeft(Path path, double x, double y, double base) {
    if (shape.left == _EdgeType.flat) {
      path.lineTo(x, y);
      return;
    }
    // La dirección invierte la curva: pestaña hacia afuera o encaje hacia adentro.
    final direction = shape.left == _EdgeType.tab ? -1.0 : 1.0;
    path.lineTo(x, y + base * 0.75);
    path.cubicTo(
      x + direction * knobSize * 0.2,
      y + base * 0.75,
      x + direction * knobSize,
      y + base * 0.65,
      x + direction * knobSize,
      y + base * 0.5,
    );
    path.cubicTo(
      x + direction * knobSize,
      y + base * 0.35,
      x + direction * knobSize * 0.2,
      y + base * 0.25,
      x,
      y + base * 0.25,
    );
    path.lineTo(x, y);
  }

  @override
  bool shouldReclip(covariant _JigsawClipper oldClipper) {
    return oldClipper.shape != shape || oldClipper.knobSize != knobSize;
  }
}

class _JigsawBorderPainter extends CustomPainter {
  final _JigsawShape shape;
  final double knobSize;
  final Color borderColor;
  final double borderWidth;
  final Color? shadowColor;

  const _JigsawBorderPainter({
    required this.shape,
    required this.knobSize,
    required this.borderColor,
    required this.borderWidth,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _JigsawClipper(shape: shape, knobSize: knobSize).getClip(size);

    if (shadowColor != null) {
      canvas.drawShadow(path, shadowColor!, 6, true);
    }

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _JigsawBorderPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.knobSize != knobSize ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.shadowColor != shadowColor;
  }
}
