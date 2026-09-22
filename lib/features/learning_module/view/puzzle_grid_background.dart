import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Fondo de rompecabezas para la vista de nivel.
///
/// Reparte las imagenes del nivel en piezas asimetricas que encajan entre si,
/// como un bento, y las hace respirar con una animacion lenta: cada pieza
/// se expande o contrae unos pixeles con una fase distinta, de modo que las
/// divisiones parecen moverse sin dejar huecos. Todo a muy baja opacidad,
/// para que decore sin competir con el selector.
class PuzzleGridBackground extends StatefulWidget {
  final List<String> imageUrls;
  final double opacity;
  final bool animate;

  const PuzzleGridBackground({
    super.key,
    required this.imageUrls,
    this.opacity = 0.10,
    this.animate = true,
  });

  @override
  State<PuzzleGridBackground> createState() => _PuzzleGridBackgroundState();
}

class _PuzzleGridBackgroundState extends State<PuzzleGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Piezas en fracciones del lienzo (x, y, ancho, alto). Es un unico patron
  // fijo, pensado para que ninguna pieza quede alineada con su vecina y el
  // conjunto se lea como rompecabezas y no como cuadricula.
  static const List<Rect> _pattern = [
    Rect.fromLTWH(0.00, 0.00, 0.42, 0.26),
    Rect.fromLTWH(0.42, 0.00, 0.58, 0.18),
    Rect.fromLTWH(0.00, 0.26, 0.28, 0.30),
    Rect.fromLTWH(0.28, 0.18, 0.42, 0.22),
    Rect.fromLTWH(0.70, 0.18, 0.30, 0.38),
    Rect.fromLTWH(0.28, 0.40, 0.42, 0.16),
    Rect.fromLTWH(0.00, 0.56, 0.36, 0.24),
    Rect.fromLTWH(0.36, 0.56, 0.34, 0.24),
    Rect.fromLTWH(0.70, 0.56, 0.30, 0.24),
    Rect.fromLTWH(0.00, 0.80, 0.50, 0.20),
    Rect.fromLTWH(0.50, 0.80, 0.50, 0.20),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PuzzleGridBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (int i = 0; i < _pattern.length; i++)
                    _buildPiece(
                      index: i,
                      base: _pattern[i],
                      t: t,
                      width: w,
                      height: h,
                      url: urls[i % urls.length],
                      borderColor: colors.surfaceBorder,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPiece({
    required int index,
    required Rect base,
    required double t,
    required double width,
    required double height,
    required String url,
    required Color borderColor,
  }) {
    // Cada pieza respira con una fase propia. La amplitud es pequena (2% del
    // lienzo) para que el movimiento se perciba como vida, no como distraccion.
    final phase = index * 0.9;
    final dx = math.sin(t + phase) * 0.012;
    final dy = math.cos(t * 0.8 + phase) * 0.012;
    final grow = 1.0 + math.sin(t * 0.6 + phase * 1.3) * 0.02;

    final rectW = base.width * grow;
    final rectH = base.height * grow;
    final left = (base.left + dx - (rectW - base.width) / 2) * width;
    final top = (base.top + dy - (rectH - base.height) / 2) * height;

    return Positioned(
      left: left,
      top: top,
      width: rectW * width,
      height: rectH * height,
      child: Opacity(
        opacity: widget.opacity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: borderColor, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Transform.scale(scale: 1.06, child: _buildImage(url)),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
