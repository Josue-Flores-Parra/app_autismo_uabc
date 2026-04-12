import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/content_card_model.dart';

class RadialFocusPreviewSelector extends StatefulWidget {
  final List<ContentCardData> contents;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final ValueChanged<int>? onFocusedNodePressed;

  const RadialFocusPreviewSelector({
    super.key,
    required this.contents,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.onFocusedNodePressed,
  });

  @override
  State<RadialFocusPreviewSelector> createState() => _RadialFocusPreviewSelectorState();
}

class _RadialFocusPreviewSelectorState extends State<RadialFocusPreviewSelector>
    with SingleTickerProviderStateMixin {
  // Se usa un ancla muy alta para iniciar lejos de cero y permitir avanzar/retroceder
  // muchas veces sin "sentir" los limites de un indice finito.
  //
  // Diseno: el carrusel debe comportarse como rueda continua (infinita), aunque
  // el dataset sea finito. Esto simplifica la UX (sin topes) y evita estados
  // especiales al cruzar el primer/ultimo elemento.
  static const int _virtualAnchor = 10000;

  // Ajusta cuanto gira la rueda por cada delta angular del dedo.
  // Valor < 1 amortigua el gesto para mejorar control fino en pantallas pequenas.
  // Valor > 1 se siente mas "nervioso" y puede generar saltos involuntarios.
  static const double _dragSensitivity = 0.60;

  late int _virtualIndex;
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  double? _lastPointerAngle;
  double _dragAccumulator = 0;
  bool _isDragging = false;

  int get _length => widget.contents.length;

  double get _stepAngle {
    // Cada item ocupa una porcion uniforme de la circunferencia.
    // Caso especial de 2 items: forzamos pi para ubicarlos en extremos opuestos
    // y evitar geometria rara en la rueda.
    if (_length <= 1) return 1;
    if (_length == 2) return math.pi;
    return (2 * math.pi) / _length;
  }

  int _logicalFromVirtual(int virtualIndex) {
    if (_length == 0) return 0;
    // Convierte el indice virtual (puede crecer/disminuir sin limite) al rango real [0, _length).
    final mod = virtualIndex % _length;
    return mod < 0 ? mod + _length : mod;
  }

  int _normalizeInitialIndex(int index) {
    if (_length == 0) return 0;
    // Permite recibir indices fuera de rango y normalizarlos sin fallar.
    // Diseno defensivo: evita acoplar el widget a validaciones externas.
    final mod = index % _length;
    return mod < 0 ? mod + _length : mod;
  }

  int _alignedAnchor() {
    if (_length <= 0) return _virtualAnchor;
    // Garantiza que logicalFromVirtual(anchor) == 0 para cualquier length.
    // Sin esta alineación, un anchor fijo (ej. 10000) puede caer en módulo
    // distinto de 0 y provocar desfase entre nodo visible y contenido seleccionado.
    return _virtualAnchor - (_virtualAnchor % _length);
  }

  int get _selectedLogicalIndex => _logicalFromVirtual(_virtualIndex);

  double get _dragPhase => _dragAccumulator / _stepAngle;

  @override
  void initState() {
    super.initState();
    final initial = _normalizeInitialIndex(widget.initialIndex);
    // Arrancamos desde anchor alineado + initial para que el primer frame ya
    // esté sincronizado con el índice que espera la pantalla contenedora.
    _virtualIndex = _alignedAnchor() + initial;

    // Se anima solo el acumulador de arrastre (no el indice logico directamente)
    // para mantener continuidad visual durante el snap sin disparar cambios de
    // contenido intermedios.
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

    if (_length == 0) { // Si el widget se actualiza a un estado sin contenido, reseteamos el indice virtual para evitar inconsistencias.
      _virtualIndex = _virtualAnchor;
      return;
    }

    if (oldWidget.contents != widget.contents && _selectedLogicalIndex >= _length) {
      // Si cambia la fuente de datos y el indice actual queda invalido,
      // volvemos a inicio para garantizar estado consistente y notificacion unica.
      // También usamos anchor alineado para no reintroducir el desfase inicial.
      _virtualIndex = _alignedAnchor();
      widget.onIndexChanged?.call(0);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  // Convierte la posición global del puntero en un ángulo relativo al centro del widget.
  double _pointerAngle(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;

    final local = box.globalToLocal(globalPosition);
    final center = box.size.center(Offset.zero);

    // Decidimos medir en coordenadas angulares respecto al centro del widget
    // (no por desplazamiento X/Y) para que el gesto sea radial y consistente,
    // incluso si el usuario arrastra en diagonales.
    return math.atan2(local.dy - center.dy, local.dx - center.dx);
  }

  double _normalizeDelta(double delta) {
    // Mantiene el delta angular en [-pi, pi] para evitar saltos al cruzar el corte circular.
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    return delta;
  }

  // Al iniciar un gesto, detenemos cualquier animación de snap en curso para que el control vuelva inmediatamente al usuario.
  void _onPanStart(DragStartDetails details) {
    _snapController.stop();
    // Al iniciar un nuevo gesto, cancelamos cualquier snap en progreso para no
    // mezclar dos fuentes de movimiento (animacion + dedo) sobre el mismo estado.
    _lastPointerAngle = _pointerAngle(details.globalPosition);
    if (!_isDragging) {
      setState(() {
        _isDragging = true;
      });
    }
  }
  // Durante el arrastre, acumulamos el delta angular y lo convertimos en pasos discretos para cambiar el item seleccionado.
  void _onPanUpdate(DragUpdateDetails details) {
    if (_length <= 1) return;

    final currentAngle = _pointerAngle(details.globalPosition);
    if (_lastPointerAngle == null) {
      _lastPointerAngle = currentAngle;
      return;
    }

    final delta = _normalizeDelta(currentAngle - _lastPointerAngle!);
    _lastPointerAngle = currentAngle;

    // Acumula giro continuo y lo convierte en pasos discretos por item.
    // Diseno: separar acumulador continuo + indice discreto evita jitter visual
    // y notificaciones excesivas al ViewModel.
    _dragAccumulator += delta * _dragSensitivity;
    final steps = (_dragAccumulator / _stepAngle).truncate();

    if (steps != 0) {
      _virtualIndex -= steps;
      _dragAccumulator -= steps * _stepAngle;

      // Solo notificamos cuando hay cambio real de item enfocado, no por cada
      // frame del gesto. Esto reduce recomposiciones aguas arriba.
      widget.onIndexChanged?.call(_selectedLogicalIndex);
    }

    setState(() {});
  }

  // Al finalizar el gesto, animamos el snap hacia el item más cercano para garantizar que siempre terminamos con un item perfectamente centrado, evitando estados intermedios ambiguos.
  void _animateSnapToNearest() {
    // Si no hay contenido o solo hay uno, no tiene sentido animar el snap ni cambiar el estado de arrastre.
    if (_length <= 1) {
      setState(() {
        _dragAccumulator = 0;
        _isDragging = false;
      });
      return;
    }

    // Al soltar, cierra el arrastre hacia el item mas cercano para dejar el foco alineado.
    // Diseno UX: siempre terminar en "estado estable" (item centrado) mejora
    // legibilidad y evita focos intermedios ambiguos.
    final snapSteps = _dragPhase.round();
    final targetAccumulator = snapSteps * _stepAngle;

    if ((targetAccumulator - _dragAccumulator).abs() < 0.0001) {
      if (snapSteps != 0) {
        setState(() {
          _virtualIndex -= snapSteps;
          _dragAccumulator = 0;
          _isDragging = false;
        });
        // Mantener callback tambien en el camino "sin animacion" para que
        // ambos flujos (con/sin tween) tengan la misma semantica externa.
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

    // easeOutCubic prioriza respuesta rapida inicial y frenado suave al final,
    // percepcion alineada con controles tactiles "fisicos".
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

                // El centro visual se desplaza hacia arriba para dejar espacio
                // al label/titulo debajo sin recortar la orbita inferior.

                final nodeSize = math.min(
                  constraints.maxWidth * 0.74,
                  constraints.maxHeight * 0.78,
                );

                // nodeSize se deriva de ambos ejes para conservar proporcion
                // circular y evitar que el widget "rompa" en layouts extremos.

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

                // Se usa orbita eliptica (X != Y) para reforzar sensacion de profundidad
                // y reducir solapamiento vertical de nodos en pantallas bajas.
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

                  // topness modela "cercania" al frente: 1 arriba (foco), 0 abajo (fondo).
                  // Sobre esa variable se mapean opacidad y blur para dar lectura espacial.
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

                // Ordena por profundidad para que los nodos del fondo se dibujen primero.
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
                          
                          // Para acercar la experiencia a preview_cards, cada nodo puede
                          // renderizar miniatura cuando el contenido lo permite.
                          child: _RadialNode(
                            size: nodeSize,
                            blurSigma: radialNode.blurSigma,
                            content: widget.contents[radialNode.logicalIndex],
                            activityAssetPath: _activityAssetForContent(
                              widget.contents[radialNode.logicalIndex],
                            ),
                            fallbackIcon: _fallbackIconForType(
                              widget.contents[radialNode.logicalIndex].type,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: selectorCenter.dx - (nodeSize / 2),
                      top: selectorCenter.dy - (nodeSize / 2),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_isDragging) return;
                          widget.onFocusedNodePressed?.call(_selectedLogicalIndex);
                        },
                        child: SizedBox(width: nodeSize, height: nodeSize),
                      ),
                    ),
                    Positioned(
                      left: selectorCenter.dx - 36,
                      top: selectorCenter.dy - (nodeSize / 2) - 56,
                      // Hint fuera del area central para no competir con el foco visual.
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

  // Mapea tipos de contenido a iconos específicos para el carrusel radial
  String? _activityAssetForContent(ContentCardData content) {
    // Iconos temporales de actividades en carrusel radial.
    // Pictograma usa PNG temporal, video/minijuego se mantienen en SVG.
    if (content.type == ContentType.pictogram) {
      return 'assets/icons/minigame_pictogram.png';
    }

    if (content.type == ContentType.video) {
      return 'assets/icons/minigame_video.svg';
    }

    if (content.type == ContentType.miniGame && content.miniGameType == 'simple_selection') {
      return 'assets/icons/minigame_simple_selection.svg';
    }

    return null;
  }

  IconData _fallbackIconForType(ContentType type) {
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
    // Chip compacto para reforzar el tipo de contenido sin ocupar altura extra.
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

        // El anillo es un "target" visual: da contexto de foco sin usar sombra
        // pesada sobre el item principal para no contaminar contraste del icono.
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
  final ContentCardData content;
  final String? activityAssetPath;
  final IconData fallbackIcon;

  const _RadialNode({
    required this.size,
    required this.blurSigma,
    required this.content,
    required this.activityAssetPath,
    required this.fallbackIcon,
  });

  // Solo mostramos la imagen para nodos de tipo pictograma, esto porque se obtiene el preview desde Firebase,
  // Para los demas tipo de actividades usamos los iconos personalizados en assets/
  bool get _shouldShowPictogramImage {
    // Si existe icono dedicado para el tipo, priorizamos ese asset para mantener
    // consistencia visual del carrusel.
    return content.type == ContentType.pictogram &&
        activityAssetPath == null &&
        content.imagePath.trim().isNotEmpty;
  }

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

                // Gradiente frio para mantener coherencia visual con la identidad
                // del modulo y diferenciar nodos "pasivos" del contenido central.
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
            child: SizedBox(
              width: size * 0.72,
              height: size * 0.72,
              child: _shouldShowPictogramImage // Checar si la actividad es pictograma para mostrar su preview, si no, se usara el icono personalizado
                  ? ClipOval(
                      child: _buildNodeImage(
                        content.imagePath,
                        fit: BoxFit.cover,
                        shimmerBaseColor: const Color(0xFF2E5574),
                        fallback: Icon(
                          fallbackIcon,
                          size: size * 0.4,
                          color: const Color(0xE6FFFFFF),
                        ),
                      ),
                    )
                  : _buildActivityIcon(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIcon() {
    if (activityAssetPath == null) {
      return Icon(
        fallbackIcon,
        size: size * 0.4,
        color: const Color(0xE6FFFFFF),
      );
    }

    // revisamos si no es SVG para ajustar el widget de carga, ya que SvgPicture no soporta errorBuilder como Image.asset.
    if (!activityAssetPath!.toLowerCase().endsWith('.svg')) {
      return Image.asset(
        activityAssetPath!,
        width: size * 0.42,
        height: size * 0.42,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          size: size * 0.4,
          color: const Color(0xE6FFFFFF),
        ),
      );
    }

    return SvgPicture.asset(
      activityAssetPath!,
      width: size * 0.42,
      height: size * 0.42,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Icon(
        fallbackIcon,
        size: size * 0.4,
        color: const Color(0xE6FFFFFF),
      ),
    );
  }
}

// Construye el widget de imagen para un nodo, con soporte para carga remota y placeholder.
Widget _buildNodeImage(
  String url, {
  BoxFit fit = BoxFit.cover,
  Color shimmerBaseColor = const Color(0xFF2E5574),
  required Widget fallback,
}) {
  // Mismo criterio que preview_cards: http/https es red, el resto se interpreta como asset.
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => Center(child: fallback),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _RadialNodeShimmer(baseColor: shimmerBaseColor);
      },
    );
  }

  return Image.asset(
    url,
    fit: fit,
    errorBuilder: (_, __, ___) => Center(child: fallback),
  );
}

class _RadialNodeShimmer extends StatefulWidget {
  final Color baseColor;

  const _RadialNodeShimmer({required this.baseColor});

  @override
  State<_RadialNodeShimmer> createState() => _RadialNodeShimmerState();
}

class _RadialNodeShimmerState extends State<_RadialNodeShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
        final r = (widget.baseColor.r * 255.0).clamp(0, 255).round();
        final g = (widget.baseColor.g * 255.0).clamp(0, 255).round();
        final b = (widget.baseColor.b * 255.0).clamp(0, 255).round();
        final brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255;
        final highlightColor = brightness > 0.5
            ? Color.fromARGB(255, (r * 0.85).round(), (g * 0.85).round(), (b * 0.85).round())
            : Color.fromARGB(
                255,
                (r + (255 - r) ~/ 2).clamp(0, 255),
                (g + (255 - g) ~/ 2).clamp(0, 255),
                (b + (255 - b) ~/ 2).clamp(0, 255),
              );

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.baseColor,
                highlightColor,
                widget.baseColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: widget.baseColor,
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

// Widget de hint para indicar al usuario que el carrusel es deslizable. Se muestra de forma persistente pero se atenúa durante el gesto para no competir con el foco visual una vez que el usuario ha comprendido la interacción.
class _ScrollHint extends StatelessWidget {
  final bool isDragging;

  const _ScrollHint({required this.isDragging});

  @override
  Widget build(BuildContext context) {
    final opacity = isDragging ? 0.22 : 0.78;

    // El hint se atenúa durante el gesto para no distraer cuando el usuario
    // ya entendio la interaccion y esta ejecutando una accion activa.

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

