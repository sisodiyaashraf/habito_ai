import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaterWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double animationValue;
  final Color color;

  WaterWavePainter({
    required this.progress,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Calculate water level: progress 0.0 (start) = 0.0 (top), progress 1.0 (end) = height (bottom)
    final waterLevel = size.height * progress;
    
    path.moveTo(0, waterLevel);
    
    // Draw wave
    for (double i = 0; i <= size.width; i++) {
      final waveHeight = 5 * math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi));
      path.lineTo(i, waterLevel + waveHeight);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw a second wave with different phase and opacity for more depth
    final secondPath = Path();
    final secondPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
      
    secondPath.moveTo(0, waterLevel);
    for (double i = 0; i <= size.width; i++) {
      final waveHeight = 8 * math.sin((i / size.width * 2 * math.pi) - (animationValue * 2 * math.pi) + math.pi/2);
      secondPath.lineTo(i, waterLevel + waveHeight);
    }
    secondPath.lineTo(size.width, size.height);
    secondPath.lineTo(0, size.height);
    secondPath.close();
    
    canvas.drawPath(secondPath, secondPaint);
  }

  @override
  bool shouldRepaint(covariant WaterWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.animationValue != animationValue;
  }
}
