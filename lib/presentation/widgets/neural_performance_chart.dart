import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hive_provider.dart';

class NeuralPerformanceChart extends StatelessWidget {
  const NeuralPerformanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final contributions = hive.squadPerformanceData; //
    final badges = hive.memberBadges; //
    final members = hive.members;

    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            "SQUAD GEOMETRY",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 10,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final center = Offset(
                  constraints.maxWidth / 2,
                  constraints.maxHeight / 2,
                );
                final radius =
                    math.min(constraints.maxWidth, constraints.maxHeight) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. The Core Radar Visualization
                    CustomPaint(
                      size: Size.infinite,
                      painter: RadarPainter(contributions),
                    ),

                    // 2. The Neural Badge Overlay
                    ...List.generate(members.length, (index) {
                      final member = members[index];
                      final badgeText = badges[member.id];

                      if (badgeText == null) return const SizedBox.shrink();

                      // Calculate badge position relative to chart vertices
                      final angle =
                          (2 * math.pi / members.length) * index -
                          (math.pi / 2);
                      const double labelOffset =
                          1.35; // Position outside the web

                      return Positioned(
                        left:
                            center.dx +
                            (radius * labelOffset) * math.cos(angle) -
                            40,
                        top:
                            center.dy +
                            (radius * labelOffset) * math.sin(angle) -
                            10,
                        child: _buildNeuralBadge(badgeText),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralBadge(String label) {
    final isCritical = label.contains("OFFLINE");
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF060912),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.cyanAccent.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isCritical
                ? Colors.redAccent.withOpacity(0.2)
                : Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isCritical ? Colors.redAccent : Colors.cyanAccent,
          fontSize: 7,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final List<double> data;
  RadarPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final angleStep = (2 * math.pi) / data.length;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw background concentric webs
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), linePaint);
    }

    // Draw axial lines
    for (var i = 0; i < data.length; i++) {
      final x = center.dx + radius * math.cos(i * angleStep - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angleStep - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), linePaint);
    }

    // Draw the collective performance polygon
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final val = data[i].clamp(0.2, 1.0); // Ensure minimal visibility
      final x =
          center.dx + radius * val * math.cos(i * angleStep - math.pi / 2);
      final y =
          center.dy + radius * val * math.sin(i * angleStep - math.pi / 2);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
