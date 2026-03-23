import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../model/content_card_model.dart';

class RadialFocusPreviewSelector extends StatefulWidget {
  final List<ContentCardData> contents;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  const RadialFocusPreviewSelector({
    super.key,
    required this.contents,
    this.initialIndex = 0,
    this.onIndexChanged,
  });

  @override
  State<RadialFocusPreviewSelector> createState() => _RadialFocusPreviewSelectorState();
}

class _RadialFocusPreviewSelectorState extends State<RadialFocusPreviewSelector>
    with SingleTickerProviderStateMixin {
  static const int _virtualAnchor = 10000;
  static const double _dragSensitivity = 0.62;

  late int _virtualIndex;
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  double? _lastPointerAngle;
  double _dragAccumulator = 0;
  bool _isDragging = false;

  int get _length => widget.contents.length;

  double get _stepAngle {
    if (_length <= 1) return 1;
    if (_length == 2) return math.pi;
    return (2 * math.pi) / _length;
  }

  int _logicalFromVirtual(int virtualIndex) {
    if (_length == 0) return 0;
    final mod = virtualIndex % _length;
    return mod < 0 ? mod + _length : mod;
  }

  int _normalizeInitialIndex(int index) {
    if (_length == 0) return 0;
    final mod = index % _length;
    return mod < 0 ? mod + _length : mod;
  }

  int get _selectedLogicalIndex => _logicalFromVirtual(_virtualIndex);

  double get _dragPhase => _dragAccumulator / _stepAngle;

  @override
  void initState() {
    super.initState();
    final initial = _normalizeInitialIndex(widget.initialIndex);
    _virtualIndex = _virtualAnchor + initial;

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
        final animation = _snapAnimation;
        if (animation == null || !mounted) return;
        setState(() {
          _dragAccumulator = animation.value;
        });
      });
  }

  @override
  void didUpdateWidget(covariant RadialFocusPreviewSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_length == 0) {
      _virtualIndex = _virtualAnchor;
      return;
    }

    if (oldWidget.contents != widget.contents && _selectedLogicalIndex >= _length) {
      _virtualIndex = _virtualAnchor;
      widget.onIndexChanged?.call(0);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double _pointerAngle(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;

    final local = box.globalToLocal(globalPosition);
    final center = box.size.center(Offset.zero);
    return math.atan2(local.dy - center.dy, local.dx - center.dx);
  }

  double _normalizeDelta(double delta) {
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    return delta;
  }

  void _onPanStart(DragStartDetails details) {
    _snapController.stop();
    _lastPointerAngle = _pointerAngle(details.globalPosition);
    if (!_isDragging) {
      setState(() {
        _isDragging = true;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_length <= 1) return;

    final currentAngle = _pointerAngle(details.globalPosition);
    if (_lastPointerAngle == null) {
      _lastPointerAngle = currentAngle;
      return;
    }

    final delta = _normalizeDelta(currentAngle - _lastPointerAngle!);
    _lastPointerAngle = currentAngle;

    _dragAccumulator += delta * _dragSensitivity;
    final steps = (_dragAccumulator / _stepAngle).truncate();

    if (steps != 0) {
      _virtualIndex -= steps;
      _dragAccumulator -= steps * _stepAngle;
      widget.onIndexChanged?.call(_selectedLogicalIndex);
    }

    setState(() {});
  }

  void _animateSnapToNearest() {
    if (_length <= 1) {
      setState(() {
        _dragAccumulator = 0;
        _isDragging = false;
      });
      return;
    }

    final snapSteps = _dragPhase.round();
    final targetAccumulator = snapSteps * _stepAngle;

    if ((targetAccumulator - _dragAccumulator).abs() < 0.0001) {
      if (snapSteps != 0) {
        setState(() {
          _virtualIndex -= snapSteps;
          _dragAccumulator = 0;
          _isDragging = false;
        });
        widget.onIndexChanged?.call(_selectedLogicalIndex);
      } else {
        setState(() {
          _dragAccumulator = 0;
          _isDragging = false;
        });
      }
      return;
    }

    _snapAnimation = Tween<double>(
      begin: _dragAccumulator,
      end: targetAccumulator,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic));

    _snapController
      ..stop()
      ..reset();
    _snapController.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _virtualIndex -= snapSteps;
        _dragAccumulator = 0;
        _isDragging = false;
      });
      if (snapSteps != 0) {
        widget.onIndexChanged?.call(_selectedLogicalIndex);
      }
    });
  }

  void _onPanEnd(DragEndDetails _) {
    _lastPointerAngle = null;
    _isDragging = false;
    _animateSnapToNearest();
  }

  @override
  Widget build(BuildContext context) {
    if (_length == 0) {
      return const SizedBox.shrink();
    }

    final selected = widget.contents[_selectedLogicalIndex];
    final selectedTypeLabel = _typeLabelFor(selected.type);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () {
        _lastPointerAngle = null;
        _isDragging = false;
        _animateSnapToNearest();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final selectorCenter = Offset(
                  constraints.maxWidth / 2,
                  constraints.maxHeight * 0.42,
                );

                final nodeSize = math.min(
                  constraints.maxWidth * 0.74,
                  constraints.maxHeight * 0.78,
                );

                // Trayectoria radial: el nodo seleccionado se mantiene fijo en el punto
                // superior de la circunferencia y los demas entran/salen desde abajo.
                final orbitRadiusX = math.max(
                  nodeSize * 0.95,
                  constraints.maxWidth * 0.86,
                );
                final orbitRadiusY = math.max(
                  nodeSize * 0.72,
                  constraints.maxHeight * 0.52,
                );
                final orbitCenter = Offset(
                  selectorCenter.dx,
                  selectorCenter.dy + orbitRadiusY,
                );

                final radialNodes = <_RadialNodeLayout>[];
                final orbitCount = _length;

                for (int offset = 0; offset < orbitCount; offset++) {
                  final logical = _logicalFromVirtual(_virtualIndex + offset);
                  final angle = (-math.pi / 2) + ((offset + _dragPhase) * _stepAngle);
                  final topness = ((-math.sin(angle) + 1) / 2).clamp(0.0, 1.0);
                  final opacity = 0.16 + (topness * 0.48);
                  final blurSigma = 0.2 + ((1 - topness) * 2.2) + (_isDragging ? 0.25 : 0.0);
                  final center = Offset(
                    orbitCenter.dx + math.cos(angle) * orbitRadiusX,
                    orbitCenter.dy + math.sin(angle) * orbitRadiusY,
                  );

                  radialNodes.add(
                    _RadialNodeLayout(
                      logicalIndex: logical,
                      center: center,
                      opacity: opacity,
                      blurSigma: blurSigma,
                      depth: topness,
                    ),
                  );
                }

                radialNodes.sort((a, b) => a.depth.compareTo(b.depth));

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: selectorCenter.dx - (nodeSize / 2),
                      top: selectorCenter.dy - (nodeSize / 2),
                      child: _SelectorRing(size: nodeSize),
                    ),
                    for (final radialNode in radialNodes)
                      Positioned(
                        left: radialNode.center.dx - (nodeSize / 2),
                        top: radialNode.center.dy - (nodeSize / 2),
                        child: Opacity(
                          opacity: radialNode.opacity,
                          child: _RadialNode(
                            size: nodeSize,
                            blurSigma: radialNode.blurSigma,
                            icon: _iconForType(widget.contents[radialNode.logicalIndex].type),
                          ),
                        ),
                      ),
                    Positioned(
                      left: selectorCenter.dx - 36,
                      top: selectorCenter.dy - (nodeSize / 2) - 38,
                      child: _ScrollHint(isDragging: _isDragging),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _buildTypeLabel(selectedTypeLabel),
          const SizedBox(height: 10),
          if ((selected.description ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                selected.description!,
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  IconData _iconForType(ContentType type) {
    switch (type) {
      case ContentType.pictogram:
        return Icons.image_outlined;
      case ContentType.video:
        return Icons.play_circle_outline;
      case ContentType.audio:
        return Icons.graphic_eq_rounded;
      case ContentType.miniGame:
        return Icons.videogame_asset_outlined;
    }
  }

  String _typeLabelFor(ContentType type) {
    switch (type) {
      case ContentType.pictogram:
        return 'PICTOGRAMA';
      case ContentType.video:
        return 'VIDEO';
      case ContentType.audio:
        return 'AUDIO';
      case ContentType.miniGame:
        return 'MINIJUEGO';
    }
  }

  Widget _buildTypeLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5B7A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SelectorRing extends StatelessWidget {
  final double size;

  const _SelectorRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF9EDFFF), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA66C6FF),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(0x5548A8E6),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _RadialNode extends StatelessWidget {
  final double size;
  final double blurSigma;
  final IconData icon;

  const _RadialNode({
    required this.size,
    required this.blurSigma,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4E7A9C), Color(0xFF2E5574)],
                ),
                border: Border.all(color: const Color(0x88FFFFFF), width: 1.1),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: size * 0.4,
              color: const Color(0xE6FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialNodeLayout {
  final int logicalIndex;
  final Offset center;
  final double opacity;
  final double blurSigma;
  final double depth;

  const _RadialNodeLayout({
    required this.logicalIndex,
    required this.center,
    required this.opacity,
    required this.blurSigma,
    required this.depth,
  });
}

class _ScrollHint extends StatelessWidget {
  final bool isDragging;

  const _ScrollHint({required this.isDragging});

  @override
  Widget build(BuildContext context) {
    final opacity = isDragging ? 0.22 : 0.78;

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: opacity,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x2222384A),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x55FFFFFF), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_double_arrow_left_rounded,
                    size: 18, color: Color(0xCCFFFFFF)),
                SizedBox(width: 2),
                Icon(Icons.circle, size: 6, color: Color(0xAAFFFFFF)),
                SizedBox(width: 2),
                Icon(Icons.keyboard_double_arrow_right_rounded,
                    size: 18, color: Color(0xCCFFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

