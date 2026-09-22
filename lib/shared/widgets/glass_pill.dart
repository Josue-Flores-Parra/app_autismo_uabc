import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Pastilla translucida para encabezados que van sobre fondos ilustrados.
///
/// Con `color` se vuelve opaca (por ejemplo `colors.surface`) para leerse
/// sobre imagenes claras en modo oscuro.
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  const GlassPill({
    super.key,
    required this.child,
    required this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pill = Container(
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? colors.glassFill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color == null ? colors.glassBorder : colors.surfaceBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return pill;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: pill,
      ),
    );
  }
}
