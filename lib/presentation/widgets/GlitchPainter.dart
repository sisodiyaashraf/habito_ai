import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GlitchPainter extends CustomPainter {
  final double progress;
  GlitchPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.redAccent.withOpacity(0.3);
    final random = DateTime.now().millisecond;

    // Draw random glitch strips
    for (var i = 0; i < 5; i++) {
      double y = (random * i % size.height).toDouble();
      double h = (random % 10).toDouble() + 2;
      double x = (random * i % 20).toDouble() - 10;
      canvas.drawRect(Offset(x, y) & Size(size.width, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
