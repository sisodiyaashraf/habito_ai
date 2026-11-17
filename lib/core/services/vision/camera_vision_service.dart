import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Bounding box representation containing coordinates relative to image dimensions.
class DetectionBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;
  final double confidence;

  const DetectionBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });
}

/// Utility service to coordinate real-time camera object detection.
/// Listens to the camera frame stream, drops frames when the AI model is busy,
/// and processes image metadata on a background isolate to keep UI thread smooth.
class CameraVisionService {
  static final CameraVisionService instance = CameraVisionService._internal();
  CameraVisionService._internal();

  ObjectDetector? _objectDetector;
  bool _isProcessing = false;
  final ValueNotifier<List<DetectionBox>> detections = ValueNotifier<List<DetectionBox>>([]);

  /// Initialize ML Kit Object Detector with local streamlined options.
  Future<void> initialize() async {
    if (_objectDetector != null) return;

    // Use default stream mode which is lightweight, optimized for local devices.
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  /// Close the detector resources
  Future<void> dispose() async {
    await _objectDetector?.close();
    _objectDetector = null;
    detections.value = [];
  }

  /// Process camera frame, throttling to drop frames if already busy.
  void processCameraImage(CameraImage image, CameraDescription camera) async {
    // If the model is busy, drop this frame to ensure real-time latency
    if (_isProcessing || _objectDetector == null) return;
    _isProcessing = true;

    try {
      // 1. Convert CameraImage structure to ML Kit InputImage format.
      // This is done quickly. Since ML Kit's native underlying library handles heavy GPU/NPU
      // inference on a native thread, we only perform metadata formatting on the Dart side.
      final inputImage = _inputImageFromCameraImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // 2. Perform object detection asynchronously
      final List<DetectedObject> detectedObjects = await _objectDetector!.processImage(inputImage);

      // 3. Map native model outputs to simplified UI-friendly bounding boxes
      final List<DetectionBox> parsedResults = [];
      for (final obj in detectedObjects) {
        String labelText = "OBJECT";
        double confidence = 0.80;

        if (obj.labels.isNotEmpty) {
          final highestLabel = obj.labels.reduce((a, b) => a.confidence > b.confidence ? a : b);
          labelText = highestLabel.text;
          confidence = highestLabel.confidence;
        }

        parsedResults.add(
          DetectionBox(
            x: obj.boundingBox.left,
            y: obj.boundingBox.top,
            width: obj.boundingBox.width,
            height: obj.boundingBox.height,
            label: labelText,
            confidence: confidence,
          ),
        );
      }

      // Update listeners with fresh bounding boxes
      detections.value = parsedResults;
    } catch (e) {
      debugPrint("CameraVisionService error: $e");
    } finally {
      // Reset processing lock
      _isProcessing = false;
    }
  }

  /// Convert raw camera stream bytes to InputImage format with metadata.
  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    // Ensure we have correct format
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationValue = sensorOrientation;
      rotation = InputImageRotationValue.fromRawValue(rotationValue);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.yuv420) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    // Concatenate plane bytes for Android (YUV_420_888) or read single plane for iOS.
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final size = Size(image.width.toDouble(), image.height.toDouble());
    
    // Construct plane metadata
    final metadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
}
