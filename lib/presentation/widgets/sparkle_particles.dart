import 'dart:math';
import 'package:flutter/material.dart';

class SparkleParticles extends StatefulWidget {
  final Color color;
  const SparkleParticles({super.key, required this.color});

  @override
  State<SparkleParticles> createState() => _SparkleParticlesState();
}

class _SparkleParticlesState extends State<SparkleParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value, widget.color),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double size = 0;
  double speed = 0;

  _Particle() {
    reset();
  }

  void reset() {
    final random = Random();
    x = 0;
    y = 0;
    double angle = random.nextDouble() * 2 * pi;
    double dist = random.nextDouble() * 5;
    vx = cos(angle) * dist;
    vy = sin(angle) * dist;
    size = 2 + random.nextDouble() * 4;
    speed = 0.5 + random.nextDouble();
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter(this.particles, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.translate(size.width / 2, size.height / 2);

    for (var p in particles) {
      double t = (progress * p.speed) % 1.0;
      double x = p.vx * t * 50;
      double y = p.vy * t * 50;
      double opacity = 1.0 - t;
      
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), p.size * (1 - t), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
