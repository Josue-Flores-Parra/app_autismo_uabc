import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../model/content_card_model.dart';

class RadialFocusPreviewSelector extends StatefulWidget {
  final List<ContentCardData> contents;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final ValueChanged<int>? onFocusedNodePressed;
  final ValueChanged<bool>? onDragStateChanged;
  final bool showInlineScrollHint;

  const RadialFocusPreviewSelector({
    super.key,
    required this.contents,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.onFocusedNodePressed,
    this.onDragStateChanged,
    this.showInlineScrollHint = false,
  });

  @override
  State<RadialFocusPreviewSelector> createState() =>
      _RadialFocusPreviewSelectorState();
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
  static const double _dragSensitivity = 0.62;

  late int _virtualIndex;
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  double _dragAccumulator = 0;
  bool _isDragging = false;

  void _setDragging(bool value) {
    if (_isDragging == value) return;
    setState(() {
      _isDragging = value;
    });
    widget.onDragStateChanged?.call(value);
  }

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
    // Diseño defensivo: evita acoplar el widget a validaciones externas.
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
    _snapController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
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
      // Si el widget se actualiza a un estado sin contenido, reseteamos el indice virtual para evitar inconsistencias.
      _virtualIndex = _virtualAnchor;
      return;
    }

    if (oldWidget.contents != widget.contents &&
        _selectedLogicalIndex >= _length) {
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

  // Al iniciar un gesto, detenemos cualquier animación de snap en curso para que el control vuelva inmediatamente al usuario.
  void _onPanStart(DragStartDetails details) {
    _snapController.stop();
    // Al iniciar un nuevo gesto, cancelamos cualquier snap en progreso para no
    // mezclar dos fuentes de movimiento (animacion + dedo) sobre el mismo estado.
    _setDragging(true);
  }

  // Durante el arrastre, acumulamos el delta angular y lo convertimos en pasos discretos para cambiar el item seleccionado.
  void _onPanUpdate(DragUpdateDetails details) {
    if (_length <= 1) return;

    // UX: el carrusel debe responder al gesto horizontal real (izquierda/derecha),
    // evitando ambiguedad radial en diagonales.
    final horizontalDelta = details.delta.dx;

    // Acumula desplazamiento horizontal y lo convierte en pasos discretos por item.
    // Diseno: separar acumulador continuo + indice discreto evita jitter visual
    // y notificaciones excesivas al ViewModel.
    _dragAccumulator +=
        (horizontalDelta / 140.0) * _stepAngle * _dragSensitivity;
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
      });
      _setDragging(false);
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
        });
        _setDragging(false);
        // Mantener callback tambien en el camino "sin animacion" para que
        // ambos flujos (con/sin tween) tengan la misma semantica externa.
        widget.onIndexChanged?.call(_selectedLogicalIndex);
      } else {
        setState(() {
          _dragAccumulator = 0;
        });
        _setDragging(false);
      }
      return;
    }

    _snapAnimation =
        Tween<double>(begin: _dragAccumulator, end: targetAccumulator).animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
        );

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
      });
      _setDragging(false);
      if (snapSteps != 0) {
        widget.onIndexChanged?.call(_selectedLogicalIndex);
      }
    });
  }

  // Si el gesto se cancela abruptamente (ej. por una interrupción del sistema)
  // también animamos el snap para evitar quedar en un estado intermedio.
  void _onPanEnd(DragEndDetails _) {
    _animateSnapToNearest();
  }

  // Tocar un satelite lo trae al frente girando la rueda los pasos que haga
  // falta, en la direccion mas corta.
  void _bringToFront(int offset) {
    if (_isDragging || offset == 0 || _length <= 1) return;
    final forward = offset;
    final backward = offset - _length;
    final steps = forward.abs() <= backward.abs() ? forward : backward;

    _snapAnimation = Tween<double>(begin: 0, end: -steps * _stepAngle).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeInOutCubic),
    );
    _snapController
      ..stop()
      ..reset();
    _setDragging(true);
    _snapController.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _virtualIndex += steps;
        _dragAccumulator = 0;
      });
      _setDragging(false);
      widget.onIndexChanged?.call(_selectedLogicalIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_length == 0) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final selected = widget.contents[_selectedLogicalIndex];
    final selectedTypeLabel = _typeLabelFor(selected);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () {
        _animateSnapToNearest();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                // Cruz: el nodo enfocado va grande al centro y los demas se
                // reparten en un arco superior (izquierda, arriba, derecha),
                // todos dentro de la pantalla. Nada queda fuera de vista.
                final focusSize = math.min(width * 0.50, height * 0.52);
                final satelliteSize = focusSize * 0.55;
                final focusCenter = Offset(width / 2, height * 0.60);

                final satelliteCount = _length - 1;
                final ringRadius = math.min(
                  width * 0.38,
                  focusCenter.dy - satelliteSize / 2 - 6,
                );

                Offset slotCenter(int slot) {
                  if (slot == 0) return focusCenter;
                  if (satelliteCount == 1) {
                    return Offset(focusCenter.dx, focusCenter.dy - ringRadius);
                  }
                  // Arco de 180 grados: de la izquierda (pi) hasta la derecha (0),
                  // pasando por arriba (pi/2). Se recorre en el sentido en que
                  // giran los items al deslizar.
                  final t = (slot - 1) / (satelliteCount - 1);
                  final angle = math.pi - (t * math.pi);
                  return Offset(
                    focusCenter.dx + math.cos(angle) * ringRadius,
                    focusCenter.dy - math.sin(angle) * ringRadius,
                  );
                }

                double slotScale(int slot) => slot == 0 ? 1.0 : 0.55;
                double slotOpacity(int slot) => slot == 0 ? 1.0 : 0.62;
                double slotBlur(int slot) => slot == 0 ? 0.0 : 1.1;

                final nodes = <_RadialNodeLayout>[];
                for (int offset = 0; offset < _length; offset++) {
                  final logical = _logicalFromVirtual(_virtualIndex + offset);

                  // Posicion continua del item en la secuencia de slots:
                  // offset entero + fase del arrastre. Se interpola entre el
                  // slot actual y el siguiente para que la transicion sea
                  // fluida en vez de saltar de hueco en hueco.
                  final continuous = (offset + _dragPhase) % _length;
                  final base = continuous < 0
                      ? continuous + _length
                      : continuous;
                  final fromSlot = base.floor() % _length;
                  final toSlot = (fromSlot + 1) % _length;
                  final t = base - base.floor();

                  final center = Offset.lerp(
                    slotCenter(fromSlot),
                    slotCenter(toSlot),
                    t,
                  )!;
                  final scale = ui.lerpDouble(
                    slotScale(fromSlot),
                    slotScale(toSlot),
                    t,
                  )!;
                  final opacity = ui.lerpDouble(
                    slotOpacity(fromSlot),
                    slotOpacity(toSlot),
                    t,
                  )!;
                  final blur = ui.lerpDouble(
                    slotBlur(fromSlot),
                    slotBlur(toSlot),
                    t,
                  )!;

                  nodes.add(
                    _RadialNodeLayout(
                      logicalIndex: logical,
                      offset: offset,
                      center: center,
                      size: focusSize * scale,
                      opacity: opacity,
                      blurSigma: blur,
                      depth: scale,
                    ),
                  );
                }

                // Los satelites se dibujan primero y el enfocado al final,
                // para que quede al frente.
                nodes.sort((a, b) => a.depth.compareTo(b.depth));

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: focusCenter.dx - (focusSize / 2) - 8,
                      top: focusCenter.dy - (focusSize / 2) - 8,
                      child: _SelectorRing(
                        size: focusSize + 16,
                        color: colors.accent,
                      ),
                    ),
                    for (final node in nodes)
                      Positioned(
                        left: node.center.dx - (node.size / 2),
                        top: node.center.dy - (node.size / 2),
                        child: Opacity(
                          opacity: node.opacity,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_isDragging) return;
                              if (node.offset == 0) {
                                widget.onFocusedNodePressed?.call(
                                  _selectedLogicalIndex,
                                );
                              } else {
                                _bringToFront(node.offset);
                              }
                            },
                            child: _RadialNode(
                              size: node.size,
                              blurSigma: node.blurSigma,
                              isFocused: node.offset == 0,
                              content: widget.contents[node.logicalIndex],
                              activityAssetPath: _activityAssetForContent(
                                widget.contents[node.logicalIndex],
                              ),
                              fallbackIcon: _fallbackIconForType(
                                widget.contents[node.logicalIndex].type,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildTypeLabel(context, selectedTypeLabel),
          if (widget.showInlineScrollHint) ...[
            // Hint opcional en flujo normal para layouts que lo necesiten inline.
            const SizedBox(height: 8),
            RadialScrollHint(isDragging: _isDragging),
          ],
          const SizedBox(height: 10),
          if ((selected.description ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                selected.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.inkSoft,
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
    // Todos los iconos usan PNG locales.
    if (content.type == ContentType.pictogram) {
      return 'assets/icons/minigame_pictogram.png';
    }

    if (content.type == ContentType.video) {
      return 'assets/icons/minigame_video.png';
    }

    if (content.type == ContentType.miniGame &&
        content.miniGameType == 'simple_selection') {
      return 'assets/icons/minigame_simple_selection.png';
    }

    if (content.type == ContentType.miniGame &&
        content.miniGameType == 'puzzle') {
      return 'assets/icons/minigame_puzzle.png';
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

  String _typeLabelFor(ContentCardData content) {
    switch (content.type) {
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

  Widget _buildTypeLabel(BuildContext context, String text) {
    final colors = context.appColors;
    // Chip compacto para reforzar el tipo de contenido sin ocupar altura extra.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.surfaceBorder, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SelectorRing extends StatelessWidget {
  final double size;
  final Color color;

  const _SelectorRing({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // El anillo es un "target" visual: da contexto de foco sin usar sombra
        // pesada sobre el item principal para no contaminar contraste del icono.
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _RadialNode extends StatelessWidget {
  final double size;
  final double blurSigma;
  final bool isFocused;
  final ContentCardData content;
  final String? activityAssetPath;
  final IconData fallbackIcon;

  const _RadialNode({
    required this.size,
    required this.blurSigma,
    required this.isFocused,
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
    final colors = context.appColors;
    final iconColor = colors.ink;

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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.surface, colors.accentSoft],
                ),
                border: Border.all(
                  color: isFocused ? colors.accent : colors.surfaceBorder,
                  width: isFocused ? 2.5 : 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: size * 0.72,
              height: size * 0.72,
              child:
                  _shouldShowPictogramImage // Checar si la actividad es pictograma para mostrar su preview, si no, se usara el icono personalizado
                  ? ClipOval(
                      child: _buildNodeImage(
                        content.imagePath,
                        fit: BoxFit.cover,
                        shimmerBaseColor: colors.accentSoft,
                        fallback: Icon(
                          fallbackIcon,
                          size: size * 0.4,
                          color: iconColor,
                        ),
                      ),
                    )
                  : _buildActivityIcon(iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(Color iconColor) {
    if (activityAssetPath == null) {
      return Icon(fallbackIcon, size: size * 0.4, color: iconColor);
    }

    return Image.asset(
      activityAssetPath!,
      width: size * 0.42,
      height: size * 0.42,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, size: size * 0.4, color: iconColor),
    );
  }
}

// Construye el widget de imagen para un nodo, con soporte para carga remota y placeholder.
Widget _buildNodeImage(
  String url, {
  BoxFit fit = BoxFit.cover,
  required Color shimmerBaseColor,
  required Widget fallback,
}) {
  // Mismo criterio que preview_cards: http/https es red, el resto se interpreta como asset.
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Center(child: fallback),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _RadialNodeShimmer(baseColor: shimmerBaseColor);
      },
    );
  }

  return Image.asset(
    url,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => Center(child: fallback),
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
            ? Color.fromARGB(
                255,
                (r * 0.85).round(),
                (g * 0.85).round(),
                (b * 0.85).round(),
              )
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
  final int offset;
  final Offset center;
  final double size;
  final double opacity;
  final double blurSigma;
  final double depth;

  const _RadialNodeLayout({
    required this.logicalIndex,
    required this.offset,
    required this.center,
    required this.size,
    required this.opacity,
    required this.blurSigma,
    required this.depth,
  });
}

// Widget de hint para indicar al usuario que el carrusel es deslizable. Se muestra de forma persistente pero se atenúa durante el gesto para no competir con el foco visual una vez que el usuario ha comprendido la interacción.
class RadialScrollHint extends StatelessWidget {
  final bool isDragging;

  const RadialScrollHint({super.key, required this.isDragging});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
              color: colors.glassFill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: colors.glassBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  size: 18,
                  color: colors.ink,
                ),
                const SizedBox(width: 2),
                Icon(Icons.circle, size: 6, color: colors.inkSoft),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  size: 18,
                  color: colors.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
