import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Reserva el mismo espacio para recompensas provisionales y confirmadas.
class CompletionRewardsSection extends StatelessWidget {
  const CompletionRewardsSection({
    super.key,
    required this.loading,
    required this.loadingLabel,
    required this.children,
    this.rowCount = 3,
  });

  final bool loading;
  final String loadingLabel;
  final List<Widget> children;
  final int rowCount;

  @override
  Widget build(BuildContext context) {
    // Usa los mismos límites del diálogo (inset 40, contenido 24 y recuadro 12).
    // Así también puede responder a las medidas intrínsecas que solicita AlertDialog.
    final width = math.max(
      1.0,
      math.min(
            MediaQuery.sizeOf(context).width -
                MediaQuery.paddingOf(context).horizontal -
                80,
            560.0,
          ) -
          72,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
    var rowHeight = 24.0;
    for (final label in ['Monedas: +99999', '-100 felicidad', '-100 energía']) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: math.max(1, width - 32));
      rowHeight = math.max(rowHeight, painter.height);
      painter.dispose();
    }
    // Los avisos largos se desplazan dentro del área reservada sin mover los botones.
    return SizedBox(
      width: width,
      height: rowCount * rowHeight + (rowCount - 1) * 8,
      child: loading
          ? Semantics(
              label: loadingLabel,
              child: ExcludeSemantics(
                child: _RewardSkeleton(
                  rowCount: rowCount,
                  rowHeight: rowHeight,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    if (index > 0) const SizedBox(height: 8),
                    children[index],
                  ],
                ],
              ),
            ),
    );
  }
}

class _RewardSkeleton extends StatefulWidget {
  const _RewardSkeleton({required this.rowCount, required this.rowHeight});
  final int rowCount;
  final double rowHeight;
  @override
  State<_RewardSkeleton> createState() => _RewardSkeletonState();
}

class _RewardSkeletonState extends State<_RewardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => ShaderMask(
      key: const ValueKey('completion-rewards-shimmer'),
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final offset = _controller.value * 4 - 2;
        return LinearGradient(
          begin: Alignment(offset - 1, 0),
          end: Alignment(offset + 1, 0),
          colors: [
            Colors.white.withValues(alpha: .14),
            Colors.white.withValues(alpha: .45),
            Colors.white.withValues(alpha: .14),
          ],
        ).createShader(bounds);
      },
      child: child,
    ),
    child: Column(
      children: [
        for (var row = 0; row < widget.rowCount; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          SizedBox(
            height: widget.rowHeight,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: row == 0 ? .8 : .65,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

/// Vista previa sin plugins nativos para revisar la reserva durante la carga.
@Preview(name: 'Recompensas cargando', size: Size(280, 180))
Widget completionRewardsLoadingPreview() => const Material(
  color: Color(0xFF1A3D52),
  child: Padding(
    padding: EdgeInsets.all(12),
    child: CompletionRewardsSection(
      loading: true,
      loadingLabel: 'Cargando recompensas',
      children: [],
    ),
  ),
);
