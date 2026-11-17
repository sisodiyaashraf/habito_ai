import 'package:flutter/material.dart';
import '../../core/services/vision/camera_vision_service.dart';

/// Overlay widget that draws bounding boxes and text over the live camera preview.
class ObjectDetectionOverlay extends StatelessWidget {
  final List<DetectionBox> detections;
  final Size previewSize; // The dimensions of the incoming camera frame (e.g. 640x480)

  const ObjectDetectionOverlay({
    super.key,
    required this.detections,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: BoundingBoxPainter(
          detections: detections,
          previewSize: previewSize,
          theme: Theme.of(context),
        ),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionBox> detections;
  final Size previewSize;
  final ThemeData theme;

  BoundingBoxPainter({
    required this.detections,
    required this.previewSize,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || previewSize.width == 0 || previewSize.height == 0) return;

    // Calculate scale factors to map raw preview coordinates to device screen size.
    // In camera stream mode, the width and height of the preview frame are often swapped
    // because camera frames are captured in landscape but displayed in portrait.
    final double scaleX = size.width / previewSize.height;
    final double scaleY = size.height / previewSize.width;

    for (final detection in detections) {
      // Map coordinates from model dimension space to actual screen dimensions.
      // We flip X and Y because model coordinates are in landscape camera space.
      final double left = detection.y * scaleX;
      final double top = detection.x * scaleY;
      final double width = detection.height * scaleX;
      final double height = detection.width * scaleY;
      final Rect rect = Rect.fromLTWH(left, top, width, height);

      // Choose theme color based on label or default to cyan neon accent
      final Color accentColor = _getAccentColor(detection.label);

      // 1. Draw Bounding Box with rounded corners and a futuristic glow effect.
      final Paint glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8); // Neon glow edge

      final Paint borderPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final RRect roundedRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

      // Draw the glow shadow and the precise sharp border line
      canvas.drawRRect(roundedRect, glowPaint);
      canvas.drawRRect(roundedRect, borderPaint);

      // 2. Draw label text with high readability.
      final String labelText = "${detection.label.toUpperCase()} ${(detection.confidence * 100).toInt()}%";
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw a solid tactical background pill for label readability against any camera feed background.
      const double labelPadding = 6.0;
      final Rect labelBackground = Rect.fromLTWH(
        left,
        (top - textPainter.height - (labelPadding * 2)).clamp(0, size.height),
        textPainter.width + (labelPadding * 2),
        textPainter.height + (labelPadding * 2),
      );

      final Paint bgPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      final RRect labelRRect = RRect.fromRectAndRadius(
        labelBackground,
        const Radius.circular(6),
      );

      canvas.drawRRect(labelRRect, bgPaint);
      canvas.drawRRect(
        labelRRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      textPainter.paint(
        canvas,
        Offset(left + labelPadding, labelBackground.top + labelPadding),
      );
    }
  }

  /// Resolve futuristic colors based on the recognized item type.
  Color _getAccentColor(String label) {
    switch (label.toLowerCase()) {
      case 'book':
        return Colors.amberAccent; // Amber glow for reading verified
      case 'cup':
      case 'bottle':
        return Colors.cyanAccent; // Cyan glow for hydration verified
      default:
        return Colors.purpleAccent; // Default neon purple glow
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.previewSize != previewSize;
  }
}
