import 'dart:math' as math;
import 'package:flutter/material.dart';

class SentinelIdentityHUD extends StatefulWidget {
  final double size;
  final String label;
  final String subLabel;
  final Color themeColor;
  final double progress;
  final String? imagePath;

  const SentinelIdentityHUD({
    super.key,
    required this.size,
    required this.label,
    required this.subLabel,
    required this.themeColor,
    required this.progress,
    this.imagePath,
  });

  @override
  State<SentinelIdentityHUD> createState() => _SentinelIdentityHUDState();
}

class _SentinelIdentityHUDState extends State<SentinelIdentityHUD>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: widget.size * 0.8,
                height: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.themeColor.withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Multi-Layer HUD Rings
          _buildHUDRings(),

          // 3. Hexagonal Frame & Content
          _buildCentralCore(),

          // 4. Scanning Effect
          _buildScanningOverlay(),

          // 5. Data Fragments (Decorative)
          _buildDataFragments(),
        ],
      ),
    );
  }

  Widget _buildHUDRings() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer dashed ring
            Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _HUDRingPainter(
                  color: widget.themeColor.withValues(alpha: 0.3),
                  thickness: 1,
                  dashes: 30,
                  gap: 4,
                ),
              ),
            ),
            // Inner progress ring
            CustomPaint(
              size: Size(widget.size * 0.85, widget.size * 0.85),
              painter: _ProgressRingPainter(
                color: widget.themeColor,
                progress: widget.progress,
                thickness: 4,
              ),
            ),
            // Fast counter-rotating bit ring
            Transform.rotate(
              angle: -_rotationController.value * 6 * math.pi,
              child: CustomPaint(
                size: Size(widget.size * 0.75, widget.size * 0.75),
                painter: _HUDRingPainter(
                  color: widget.themeColor.withValues(alpha: 0.5),
                  thickness: 2,
                  dashes: 8,
                  gap: 40,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCentralCore() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Hexagon Background
        CustomPaint(
          size: Size(widget.size * 0.65, widget.size * 0.65),
          painter: _HexagonPainter(
            color: widget.themeColor.withValues(alpha: 0.1),
            filled: true,
          ),
        ),
        
        // Avatar or Icon
        ClipPath(
          clipper: _HexagonClipper(),
          child: Container(
            width: widget.size * 0.55,
            height: widget.size * 0.55,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: widget.imagePath != null && widget.imagePath!.isNotEmpty
                ? Image.asset(
                    widget.imagePath!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.shield_rounded,
                      color: widget.themeColor,
                      size: widget.size * 0.2,
                    ),
                  ),
          ),
        ),

        // Hexagon Border
        CustomPaint(
          size: Size(widget.size * 0.56, widget.size * 0.56),
          painter: _HexagonPainter(
            color: widget.themeColor,
            filled: false,
            thickness: 2,
          ),
        ),

        // Text Content (Overlayed at bottom)
        Positioned(
          bottom: widget.size * 0.15,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                    fontSize: widget.size * 0.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subLabel,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: widget.themeColor.withValues(alpha: 0.7),
                  fontSize: widget.size * 0.03,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return ClipPath(
          clipper: _HexagonClipper(),
          child: Stack(
            children: [
              Positioned(
                top: (widget.size * 0.45) + (widget.size * 0.55 * (_scanController.value - 0.5) * 2),
                child: Container(
                  width: widget.size,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        widget.themeColor.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataFragments() {
    return Stack(
      children: [
        _buildFragment("SYNC_OK", Alignment.topRight, 0.1),
        _buildFragment("SECURE", Alignment.bottomLeft, 0.2),
        _buildFragment("ID_VERIFIED", Alignment.topLeft, 0.15),
      ],
    );
  }

  Widget _buildFragment(String text, Alignment alignment, double offset) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(widget.size * offset),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: widget.themeColor.withValues(alpha: 0.2),
            fontSize: 6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _HUDRingPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final int dashes;
  final double gap;

  _HUDRingPainter({
    required this.color,
    required this.thickness,
    required this.dashes,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final double radius = size.width / 2;
    final double dashAngle = (2 * math.pi - (dashes * gap * math.pi / 180)) / dashes;
    final double gapAngle = gap * math.pi / 180;

    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        i * (dashAngle + gapAngle),
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressRingPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double thickness;

  _ProgressRingPainter({
    required this.color,
    required this.progress,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  final bool filled;
  final double thickness;

  _HexagonPainter({
    required this.color,
    required this.filled,
    this.thickness = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = i * math.pi / 3 - math.pi / 2;
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = thickness;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = i * math.pi / 3 - math.pi / 2;
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
