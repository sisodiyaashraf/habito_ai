import 'package:flutter/material.dart';
import 'dart:math';

class HabitProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color themeColor;

  HabitProgressPainter({
    required this.progress,
    this.themeColor = Colors.cyanAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        min(size.width / 2, size.height / 2) - 4; // Margin for stroke

    // 1. NEURAL TRACK (The Background)
    Paint trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // 2. OUTER GLOW LAYER (Deep Bloom)
    Paint glowPaint = Paint()
      ..color = themeColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // 3. CORE PROGRESS ARC (Sharp Neon)
    Paint corePaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    // Draw Background
    canvas.drawCircle(center, radius, trackPaint);

    // Draw Layers for the Progress Arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -pi / 2;
      final sweepAngle = 2 * pi * progress;

      // Draw the Bloom first so it sits behind the sharp core
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

      // Draw the sharp core on top
      canvas.drawArc(rect, startAngle, sweepAngle, false, corePaint);

      // 4. ADD TERMINAL END CAP (Optional: Visual Highlight at the tip)
      _drawEndCapGlow(canvas, center, radius, startAngle + sweepAngle);
    }
  }

  void _drawEndCapGlow(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
  ) {
    final capPos = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    Paint capGlow = Paint()
      ..color = themeColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(capPos, 3, capGlow);
  }

  @override
  bool shouldRepaint(HabitProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.themeColor != themeColor;
  }
}
