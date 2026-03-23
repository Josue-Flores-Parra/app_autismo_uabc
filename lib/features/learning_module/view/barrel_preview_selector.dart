import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/content_card_model.dart';

class BarrelPreviewSelector extends StatefulWidget {
  final List<ContentCardData> contents;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  const BarrelPreviewSelector({
    super.key,
    required this.contents,
    this.initialIndex = 0,
    this.onIndexChanged,
  });

  @override
  State<BarrelPreviewSelector> createState() => _BarrelPreviewSelectorState();
}

class _BarrelPreviewSelectorState extends State<BarrelPreviewSelector>
    with TickerProviderStateMixin {
  // Punto de anclaje alto para simular carrusel infinito sin llegar a limites
  // practicos del Page/Index durante una sesion normal.
  static const int _virtualAnchor = 10000; // Numero arbitrariamente alto para evitar overflow en casos normales de uso. Permite scroll infinito sin duplicar la lista real.
  // Medidas base de UI: nodos orbitantes y anillo selector fijo.
  // Se mantienen aqui para ajustar proporcion visual desde un solo lugar.
  static const double _nodeSize = 72.6;
  static const double _selectorRingSize = 90.2;
  static const double _nodePadding = 10;

  late int _virtualIndex;
  late final AnimationController _snapController;
  late final AnimationController _ringPulseController;
  Animation<double>? _snapAnimation;
  double? _lastPointerAngle;
  double _dragAccumulator = 0;
  bool _isDragging = false;

  int get _length => widget.contents.length;

  double get _stepAngle {
    // Separacion angular entre nodos sobre la orbita.
    // Caso de 2 elementos: usar PI evita que queden ambos superpuestos.
    if (_length <= 1) return 1;
    if (_length == 2) return math.pi;
    return (2 * math.pi) / _length;
  }

  int _logicalFromVirtual(int virtualIndex) {
    // Mapeo del indice virtual a logico para mantener datos acotados al largo real.
    // Este patron permite scroll infinito sin duplicar la lista.
    if (_length == 0) return 0;
    final mod = virtualIndex % _length;
    return mod < 0 ? mod + _length : mod;
  }

  int _normalizeInitialIndex(int index) {
    // Normaliza indices iniciales negativos o fuera de rango.
    if (_length == 0) return 0;
    final mod = index % _length;
    return mod < 0 ? mod + _length : mod;
  }

  int get _selectedLogicalIndex => _logicalFromVirtual(_virtualIndex);

  // Fase fraccional de arrastre. Mantener este residuo produce movimiento
  // continuo de la orbita aun cuando no se cruza un paso completo.
  double get _dragPhase => _dragAccumulator / _stepAngle;

  double get _selectorGlowIntensity {
    // Durante drag, brillo mas bajo.
    if (_isDragging) return 0.45;

    // Durante snap y pulso final, se eleva el brillo para reforzar
    // la confirmacion visual de seleccion.
    final snapGlow = _snapController.isAnimating
        ? 0.65 + (0.25 * _snapController.value)
        : 0.0;
    final pulseGlow = _ringPulseController.isAnimating
        ? 0.4 * Curves.easeOutCubic.transform(1 - _ringPulseController.value)
        : 0.0;

    return (0.6 + math.max(snapGlow, pulseGlow)).clamp(0.45, 1.2);
  }

  @override
  void initState() {
    super.initState();
    // Se inicia en ancla virtual + indice logico para habilitar orbita infinita.
    final initial = _normalizeInitialIndex(widget.initialIndex);
    _virtualIndex = _virtualAnchor + initial;
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )
      ..addListener(() {
        final animation = _snapAnimation;
        if (animation == null || !mounted) return;
        setState(() {
          // El snap anima solo el residuo angular; no toca datos directamente.
          _dragAccumulator = animation.value;
        });
      });

    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (mounted) {
          setState(() {
            // Repinta glow durante el decaimiento del pulso.
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant BarrelPreviewSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_length == 0) {
      _virtualIndex = _virtualAnchor;
      return;
    }

    // Si cambia la lista y el indice queda invalido, se resetea al inicio.
    // Priorizamos consistencia de estado sobre conservar posicion previa.
    if (oldWidget.contents != widget.contents && _selectedLogicalIndex >= _length) {
      _virtualIndex = _virtualAnchor;
      widget.onIndexChanged?.call(0);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _ringPulseController.dispose();
    super.dispose();
  }

  void _triggerRingPulse() {
    // Pulso corto para confirmar cierre de snap sin usar haptics.
    _ringPulseController
      ..stop()
      ..reset()
      ..forward();
  }

  double _pointerAngle(Offset globalPosition) {
    // Convierte puntero a angulo polar tomando el centro del widget.
    // Esto hace que el gesto sea radial, coherente con menu rotatorio.
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;

    final local = box.globalToLocal(globalPosition);
    final center = box.size.center(Offset.zero);
    return math.atan2(local.dy - center.dy, local.dx - center.dx);
  }

  double _normalizeDelta(double delta) {
    // Normaliza a [-pi, pi] para evitar saltos al cruzar el corte -pi/pi.
    // Sin esto, un movimiento pequeno puede leerse como giro gigante.
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    return delta;
  }

  void _onPanStart(DragStartDetails details) {
    // Se detienen animaciones para ceder control total al dedo del usuario.
    _snapController.stop();
    _ringPulseController.stop();
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

    _dragAccumulator += delta;
    final steps = (_dragAccumulator / _stepAngle).truncate();

    if (steps != 0) {
      // Se aplican pasos enteros al indice virtual y se conserva residuo.
      // Esta separacion evita jitter y mantiene sensibilidad uniforme.
      _virtualIndex -= steps;
      _dragAccumulator -= steps * _stepAngle;
      widget.onIndexChanged?.call(_selectedLogicalIndex);
    }

    setState(() {
      // Repinta en cada delta para movimiento continuo de nodos.
    });
  }

  void _animateSnapToNearest() {
    // Politica UX: al soltar, siempre se ajusta al nodo mas cercano.
    // Se evita dejar elementos en estado intermedio ambiguo.
    if (_length <= 1) {
      setState(() {
        _dragAccumulator = 0;
        _isDragging = false;
      });
      _triggerRingPulse();
      return;
    }

    final snapSteps = _dragPhase.round();
    final targetAccumulator = snapSteps * _stepAngle;

    if ((targetAccumulator - _dragAccumulator).abs() < 0.0001) {
      // Umbral para evitar animaciones insignificantes por error numerico.
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
      _triggerRingPulse();
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
        // Se consolida el ajuste y se limpia fase residual.
        _virtualIndex -= snapSteps;
        _dragAccumulator = 0;
        _isDragging = false;
      });
      if (snapSteps != 0) {
        widget.onIndexChanged?.call(_selectedLogicalIndex);
      }
      _triggerRingPulse();
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
                final maxNodeRadius = (_nodeSize / 2) * 1.05;
                // Limites de orbita para que los nodos no salgan de pantalla,
                // especialmente en layouts pequenos o aspect ratios extremos.
                final maxRadiusX =
                    ((constraints.maxWidth / 2) - maxNodeRadius - _nodePadding)
                        .clamp(0.0, constraints.maxWidth / 2);
                final maxRadiusY =
                    ((constraints.maxHeight * 0.58) - maxNodeRadius - _nodePadding)
                        .clamp(0.0, constraints.maxHeight * 0.58);

                final orbitRadius = math.min(
                  math.min(constraints.maxWidth, constraints.maxHeight) * 0.28,
                  math.min(maxRadiusX, maxRadiusY),
                );

                final minOrbitCenterY = orbitRadius + maxNodeRadius + _nodePadding;
                final maxOrbitCenterY = constraints.maxHeight - orbitRadius - maxNodeRadius - _nodePadding;
                final orbitCenterY = (constraints.maxHeight * 0.56)
                    .clamp(minOrbitCenterY, maxOrbitCenterY);
                final orbitCenter = Offset(constraints.maxWidth / 2, orbitCenterY);
                final selectorCenter = Offset(orbitCenter.dx, orbitCenter.dy - orbitRadius);
                // Decision de diseno: el selector vive arriba de la orbita para
                // reforzar metafora de barril (los nodos entran al aro superior).

                final nodes = <_NodeLayout>[];
                final orbitCount = _length;

                for (int offset = 0; offset < orbitCount; offset++) {
                  final logical = _logicalFromVirtual(_virtualIndex + offset);
                  final angle = (-math.pi / 2) + ((offset + _dragPhase) * _stepAngle);
                  // Profundidad para pseudo-3D: escala/opacidad varian segun posicion.
                  // No usamos transformaciones 3D reales para mantener costo bajo.
                  final depth = ((-math.sin(angle) + 1) / 2).clamp(0.0, 1.0);
                  final scale = 0.72 + (depth * 0.22);
                  final opacity = 0.38 + (depth * 0.62);

                  nodes.add(
                    _NodeLayout(
                      logicalIndex: logical,
                      center: Offset(
                        orbitCenter.dx + math.cos(angle) * orbitRadius,
                        orbitCenter.dy + math.sin(angle) * orbitRadius,
                      ),
                      scale: scale,
                      depth: depth,
                      opacity: opacity,
                    ),
                  );
                }

                nodes.sort((a, b) => a.depth.compareTo(b.depth));
                // Pintar de atras hacia adelante evita superposiciones visuales raras.

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Guia visual semitransparente para comunicar que es un menu orbital.
                    Positioned(
                      left: orbitCenter.dx - orbitRadius,
                      top: orbitCenter.dy - orbitRadius,
                      child: _OrbitGuide(radius: orbitRadius),
                    ),
                    Positioned(
                      left: selectorCenter.dx - (_selectorRingSize / 2),
                      top: selectorCenter.dy - (_selectorRingSize / 2),
                      // El anillo selector permanece fijo; lo que rota son los nodos.
                      child: _SelectorRing(glowIntensity: _selectorGlowIntensity),
                    ),
                    for (final node in nodes)
                      Positioned(
                        left: node.center.dx - (_nodeSize / 2),
                        top: node.center.dy - (_nodeSize / 2),
                        child: Opacity(
                          opacity: node.opacity,
                          child: Transform.scale(
                            scale: node.scale,
                            child: _BarrelNode(
                              emoji: _emojiForType(widget.contents[node.logicalIndex].type),
                            ),
                          ),
                        ),
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

  Widget _buildTypeLabel(String text) {
    // Se reutiliza lenguaje visual de preview_cards para consistencia global.
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

  String _typeLabelFor(ContentType type) {
    // Etiquetas en mayusculas para conservar jerarquia visual corta y legible.
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

  String _emojiForType(ContentType type) {
    switch (type) {
      case ContentType.pictogram:
        return '🖼️';
      case ContentType.video:
        return '🎬';
      case ContentType.audio:
        return '🔊';
      case ContentType.miniGame:
        return '🎮';
    }
  }
}

class _BarrelNode extends StatelessWidget {
  final String emoji;

  const _BarrelNode({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _BarrelPreviewSelectorState._nodeSize,
      height: _BarrelPreviewSelectorState._nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradiente frio para no competir cromaticamente con el glow del selector.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4E7A9C), Color(0xFF2E5574)],
        ),
        border: Border.all(
          color: const Color(0x88FFFFFF),
          width: 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x442A4A5C),
            blurRadius: 8,
            offset: Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 59.4,
        height: 59.4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Marco interno reservado para futura miniatura/imagen real.
          border: Border.all(
            color: const Color(0x66FFFFFF),
            width: 1.0,
          ),
          color: const Color(0x22000000),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NodeLayout {
  final int logicalIndex;
  final Offset center;
  final double scale;
  final double depth;
  final double opacity;

  const _NodeLayout({
    required this.logicalIndex,
    required this.center,
    required this.scale,
    required this.depth,
    required this.opacity,
  });
}

class _SelectorRing extends StatelessWidget {
  final double glowIntensity;

  const _SelectorRing({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: _BarrelPreviewSelectorState._selectorRingSize,
        height: _BarrelPreviewSelectorState._selectorRingSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Color y grosor adaptativos: mas feedback sin cambiar layout.
          border: Border.all(
            color: Color.lerp(
                  const Color(0x6695D8FF),
                  const Color(0xFF8FD9FF),
                  glowIntensity.clamp(0.0, 1.0),
                ) ??
                const Color(0xFF8FD9FF),
            width: 2.7 + (1.1 * glowIntensity),
          ),
          boxShadow: [
            // Glow externo unicamente para no contaminar contenido del nodo.
            BoxShadow(
              color: Color.lerp(
                    const Color(0x2A66C6FF),
                    const Color(0xCC66C6FF),
                    glowIntensity.clamp(0.0, 1.0),
                  ) ??
                  const Color(0xCC66C6FF),
              blurRadius: 10 + (16 * glowIntensity),
              spreadRadius: 0.4 + (2.6 * glowIntensity),
            ),
            BoxShadow(
              color: Color.lerp(
                    const Color(0x1448A8E6),
                    const Color(0x8048A8E6),
                    glowIntensity.clamp(0.0, 1.0),
                  ) ??
                  const Color(0x8048A8E6),
              blurRadius: 16 + (24 * glowIntensity),
              spreadRadius: 0.8 + (3.2 * glowIntensity),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitGuide extends StatelessWidget {
  final double radius;

  const _OrbitGuide({required this.radius});

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;

    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Baja opacidad para guiar sin distraer la lectura del contenido.
          color: const Color(0x143E7EA8),
          border: Border.all(
            color: const Color(0x667FB9DE),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7FB9DE),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}



