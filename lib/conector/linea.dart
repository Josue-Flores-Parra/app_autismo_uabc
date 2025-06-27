import 'package:flutter/material.dart';

class Connector extends CustomPainter {
  final List<Offset> positions;

  Connector(this.positions);

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 1; i < positions.length; i++) {
      final current = positions[i];
      path.lineTo(current.dx, current.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant Connector oldDelegate) {
    return oldDelegate.positions != positions;
  }
}
