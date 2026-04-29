import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../minigame_core.dart';

class PuzzleMinigame extends MinigameBase {
  const PuzzleMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
  });

  @override
  State<PuzzleMinigame> createState() => _PuzzleMinigameState();
}

class _PuzzleMinigameState extends State<PuzzleMinigame> {
  static const int _gridSize = 5;
  static const Duration _feedbackDuration = Duration(seconds: 3);
  static const double _minTraySize = 0.14;
  static const double _maxTraySize = 0.5;
  static const double _initialTraySize = 0.18;
  static const double _trayHeaderHeight = 78;

  late final String _imagePath;
  late final int _maxAttempts;
  late List<int?> _gridSlots;
  late Set<int> _trayPieces;
  final List<int> _trayOrder = <int>[];
  final math.Random _random = math.Random();
  final Set<int> _lockedPieces = <int>{};
  final Map<int, bool> _feedbackSlots = <int, bool>{};
  final DraggableScrollableController _trayController =
      DraggableScrollableController();

  int _attempts = 0;
  bool _isCompleted = false;
  bool _isChecking = false;
  bool _isTrayHovering = false;
  double _trayExtent = _initialTraySize;

  bool get _isTrayOpen => _trayExtent >= ((_minTraySize + _maxTraySize) / 2);
  bool get _isGridFull => _gridSlots.every((slot) => slot != null);

  @override
  void initState() {
    super.initState();
    _imagePath = _resolveImagePath(widget.minigameData);
    _maxAttempts = _resolveMaxAttempts(widget.minigameData);
    _gridSlots = List<int?>.filled(_gridSize * _gridSize, null);
    _trayPieces = Set<int>.from(
      List<int>.generate(_gridSize * _gridSize, (index) => index),
    );
    _syncTrayOrder(shuffle: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precachePuzzleImage();
    });
  }

  void _syncTrayOrder({bool shuffle = false}) {
    _trayOrder
      ..clear()
      ..addAll(_trayPieces);
    if (shuffle) {
      _trayOrder.shuffle(_random);
    }
  }

  void _removeFromTray(int pieceId) {
    _trayPieces.remove(pieceId);
    _trayOrder.remove(pieceId);
  }

  void _addToTray(int pieceId, {bool shuffle = false}) {
    final added = _trayPieces.add(pieceId);
    if (added) {
      _trayOrder.add(pieceId);
    }
    if (shuffle) {
      _trayOrder.shuffle(_random);
    }
  }

  Future<void> _precachePuzzleImage() async {
    try {
      await precacheImage(AssetImage(_imagePath), context);
    } catch (_) {
      // Ignorar errores de precache para no bloquear el juego.
    }
  }

  String _resolveImagePath(Map<String, dynamic> data) {
    final candidate = (data['imageUrl'] ?? data['imagePath'])
        ?.toString()
        .trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return 'assets/images/DORMIR.jpg';
  }

  int _resolveMaxAttempts(Map<String, dynamic> data) {
    final value = data['maxAttempts'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 999;
    return 999;
  }

  void _toggleTray() {
    if (_isChecking) return;
    final target = _isTrayOpen ? _minTraySize : _maxTraySize;
    _trayController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeTray() {
    if (!_isTrayOpen) return;
    _trayController.animateTo(
      _minTraySize,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  ImageProvider _imageProvider() {
    if (_imagePath.startsWith('http://') || _imagePath.startsWith('https://')) {
      return NetworkImage(_imagePath);
    }
    return AssetImage(_imagePath);
  }

  Alignment _alignmentForPiece(int pieceId) {
    final row = pieceId ~/ _gridSize;
    final col = pieceId % _gridSize;
    final step = 2 / (_gridSize - 1);
    final dx = -1 + (col * step);
    final dy = -1 + (row * step);
    return Alignment(dx, dy);
  }

  Widget _buildPieceImage(int pieceId, double pieceSize) {
    final imageSize = pieceSize * _gridSize;

    return ClipRect(
      child: OverflowBox(
        maxWidth: imageSize,
        maxHeight: imageSize,
        alignment: _alignmentForPiece(pieceId),
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

  Widget _buildDraggablePiece(int pieceId, {int? fromSlot, double size = 56}) {
    final piece = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: _buildPieceImage(pieceId, size),
        ),
      ),
    );

    return Draggable<_PuzzleDragData>(
      data: _PuzzleDragData(pieceId: pieceId, fromSlot: fromSlot),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: size + 10,
          height: size + 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildPieceImage(pieceId, size),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: piece),
      onDragStarted: () {
        if (fromSlot == null) {
          _closeTray();
        }
      },
      child: piece,
    );
  }

  void _handleGridAccept(int slotIndex, _PuzzleDragData data) {
    if (_isChecking) return;
    if (_gridSlots[slotIndex] != null) return;

    setState(() {
      if (data.fromSlot != null) {
        _gridSlots[data.fromSlot!] = null;
      } else {
        _removeFromTray(data.pieceId);
        _closeTray();
      }
      _gridSlots[slotIndex] = data.pieceId;
      _feedbackSlots.remove(slotIndex);
    });
  }

  void _handleTrayAccept(_PuzzleDragData data) {
    if (_isChecking) return;
    setState(() {
      if (data.fromSlot != null) {
        _gridSlots[data.fromSlot!] = null;
      }
      _addToTray(data.pieceId, shuffle: true);
      _feedbackSlots.remove(data.fromSlot);
    });
  }

  Future<void> _checkPuzzle() async {
    if (_isChecking || _isCompleted || !_isGridFull) return;

    final correctSlots = <int>{};
    final incorrectSlots = <int>{};
    for (int i = 0; i < _gridSlots.length; i++) {
      final pieceId = _gridSlots[i];
      if (pieceId == null) continue;
      if (pieceId == i) {
        correctSlots.add(i);
      } else {
        incorrectSlots.add(i);
      }
    }

    setState(() {
      _attempts++;
      _isChecking = true;
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

    if (incorrectSlots.isEmpty) {
      setState(() {
        _isCompleted = true;
        _isChecking = false;
        _feedbackSlots.clear();
      });
      widget.onComplete(true, _attempts);
      return;
    }

    await Future<void>.delayed(_feedbackDuration);
    if (!mounted) return;

    setState(() {
      for (final slot in incorrectSlots) {
        final pieceId = _gridSlots[slot];
        if (pieceId != null) {
          _addToTray(pieceId, shuffle: false);
        }
        _gridSlots[slot] = null;
      }
      _trayOrder.shuffle(_random);
      _feedbackSlots.clear();
      _isChecking = false;
    });

    if (_attempts >= _maxAttempts && !_isCompleted) {
      setState(() {
        _isCompleted = true;
      });
      widget.onComplete(false, _attempts);
    }
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          const Expanded(
            child: Text(
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
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return const Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Text(
        'Arrastra las piezas para completar la imagen.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xCCFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final size = rawSize.clamp(240.0, 560.0);
        final slotSize = size / _gridSize;
        return SizedBox(
          width: size,
          height: size,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: _gridSlots.length,
            itemBuilder: (context, index) {
              final pieceId = _gridSlots[index];
              final feedback = _feedbackSlots[index];
              final isLocked =
                  pieceId != null && _lockedPieces.contains(pieceId);

              return DragTarget<_PuzzleDragData>(
                onWillAccept: (data) {
                  if (_isChecking || data == null) return false;
                  if (_gridSlots[index] != null) return false;
                  if (data.fromSlot == index) return false;
                  return true;
                },
                onAccept: (data) => _handleGridAccept(index, data),
                builder: (context, candidateData, rejectedData) {
                  final highlight = candidateData.isNotEmpty;
                  final borderColor = feedback == null
                      ? (highlight
                            ? const Color(0xFF00E5FF)
                            : const Color(0x66FFFFFF))
                      : (feedback
                            ? const Color(0xFF05E995)
                            : const Color(0xFFFF5252));
                  final glowColor = feedback == null
                      ? Colors.transparent
                      : (feedback
                            ? const Color(0xFF05E995)
                            : const Color(0xFFFF5252));

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0x332C5F7A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 1.4),
                      boxShadow: [
                        if (feedback != null)
                          BoxShadow(
                            color: glowColor.withAlpha(160),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: pieceId == null
                        ? const SizedBox.shrink()
                        : (isLocked
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: _buildPieceImage(pieceId, slotSize),
                                )
                              : _buildDraggablePiece(
                                  pieceId,
                                  fromSlot: index,
                                  size: slotSize,
                                )),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

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
            onWillAccept: (data) {
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
            onAccept: (data) {
              _handleTrayAccept(data);
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
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: _gridSize,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final pieceId = _trayOrder[index];
                                      return _buildDraggablePiece(
                                        pieceId,
                                        size: 64,
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final trayOffset = (_trayExtent * screenHeight) + 12;

    return Scaffold(
      backgroundColor: const Color(0xFF091F2C),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                _buildInstruction(),
                Expanded(
                  child: IgnorePointer(
                    ignoring: _isChecking,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildGrid(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 72),
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
          ],
        ),
      ),
    );
  }

  void _snapTrayToClosest() {
    final target = _isTrayOpen ? _maxTraySize : _minTraySize;
    _trayController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTrayDragUpdate(DragUpdateDetails details, double screenHeight) {
    if (_isChecking) return;
    final delta = details.primaryDelta ?? 0;
    final nextExtent = (_trayExtent - (delta / screenHeight)).clamp(
      _minTraySize,
      _maxTraySize,
    );
    _trayController.jumpTo(nextExtent);
  }

  void _handleTrayDragEnd() {
    if (_isChecking) return;
    _snapTrayToClosest();
  }
}

class _PuzzleDragData {
  final int pieceId;
  final int? fromSlot;

  const _PuzzleDragData({required this.pieceId, required this.fromSlot});
}

void registerPuzzleMinigame() {
  MinigameFactory.register(
    MinigameType.puzzle,
    ({required onComplete, required minigameData}) =>
        PuzzleMinigame(onComplete: onComplete, minigameData: minigameData),
  );
}
