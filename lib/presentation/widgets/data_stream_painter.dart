import 'dart:math';
import 'package:flutter/material.dart';

class DataStreamPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  DataStreamPainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 30; i++) {
      double x = random.nextDouble() * size.width;
      double speed = 0.5 + random.nextDouble();
      double offset = (animation.value * speed * size.height) % size.height;
      
      canvas.drawLine(
        Offset(x, offset),
        Offset(x, offset + 20 + random.nextDouble() * 50),
        paint,
      );
      
      // Draw small "bits"
      if (random.nextDouble() > 0.8) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: random.nextBool() ? "1" : "0",
            style: TextStyle(color: color.withOpacity(0.3), fontSize: 8, fontFamily: 'SpaceMono'),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x - 4, offset));
      }
    }
  }

  @override
  bool shouldRepaint(DataStreamPainter oldDelegate) => true;
}
