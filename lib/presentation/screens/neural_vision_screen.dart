import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/services/vision/camera_vision_service.dart';
import '../../core/services/vision/habit_vision_verification_service.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';
import '../widgets/object_detection_overlay.dart';

class NeuralVisionScreen extends StatefulWidget {
  const NeuralVisionScreen({super.key});

  @override
  State<NeuralVisionScreen> createState() => _NeuralVisionScreenState();
}

class _NeuralVisionScreenState extends State<NeuralVisionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  CameraVisionService get _visionService => CameraVisionService.instance;
  HabitVisionVerificationService? _verificationService;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmActive = false;

  Future<void> _startAlarm() async {
    setState(() => _isAlarmActive = true);
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/glitch_error.mp3'));
  }

  Future<void> _stopAlarm() async {
    setState(() => _isAlarmActive = false);
    await _audioPlayer.stop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVisionSystem();
  }

  Future<void> _initializeVisionSystem() async {
    // 1. Initialize ML Kit Detector
    await _visionService.initialize();

    if (!mounted) return;

    // 2. Initialize Habit Verification logic linked to HabitProvider
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    _verificationService = HabitVisionVerificationService(
      habitProvider: habitProvider,
      context: context,
      onActivityStateChanged: (isDetecting) {
        if (isDetecting) {
          if (_isAlarmActive) {
            _stopAlarm();
          }
        } else {
          if (!_isAlarmActive) {
            _startAlarm();
          }
        }
      },
      onVerified: () async {
        await _audioPlayer.stop();
        final successPlayer = AudioPlayer();
        await successPlayer.play(
          AssetSource('sounds/scratchonix-victory-chime-366449.mp3'),
        );

        setState(() {
          _isAlarmActive = false;
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      },
    );

    // Bind verification callback to detections listener
    _visionService.detections.addListener(_onDetectionsUpdated);

    // Start beeping automatically when vision link is initialized
    _startAlarm();

    // 3. Initialize Device Cameras
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Find default back camera
        final backCam = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backCam != -1 ? backCam : 0;
        await _initCamera(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    _cameraController = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      // Start streaming images directly to CameraVisionService
      await _cameraController!.startImageStream((image) {
        if (_cameraController != null) {
          _visionService.processCameraImage(image, description);
        }
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera Controller initialize error: $e");
    }
  }

  void _onDetectionsUpdated() {
    if (_verificationService != null &&
        _visionService.detections.value.isNotEmpty) {
      _verificationService!.analyzeDetections(_visionService.detections.value);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

    setState(() => _isCameraInitialized = false);

    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
      _cameraController = null;
    }

    await _initCamera(_cameras[_selectedCameraIndex]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
      setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_cameras[_selectedCameraIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visionService.detections.removeListener(_onDetectionsUpdated);
    _cameraController?.dispose();
    _visionService.dispose();
    _verificationService?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final Color systemColor = hive.hiveStability < 0.3
        ? Colors.redAccent
        : (hive.hiveStability < 0.6 ? Colors.orangeAccent : Colors.cyanAccent);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewport Background
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),

          // 2. HUD Bounding Boxes Overlay
          if (_isCameraInitialized && _cameraController != null)
            ValueListenableBuilder<List<DetectionBox>>(
              valueListenable: _visionService.detections,
              builder: (context, boxList, child) {
                // Resolution aspect size for scaling
                final previewSize = Size(
                  _cameraController!.value.previewSize!.width,
                  _cameraController!.value.previewSize!.height,
                );
                return ObjectDetectionOverlay(
                  detections: boxList,
                  previewSize: previewSize,
                );
              },
            ),

          if (_isAlarmActive)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      width: 15,
                    ),
                  ),
                  child: Container(
                    color: Colors.redAccent.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),

          // 3. Futuristic Tactical Header HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "NEURAL_VISION_LINK",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: systemColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.flip_camera_ios_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ),

          // 4. Bounded Calibration Guideline Corners (Sight Crosshair)
          _buildSightCrosshair(systemColor),

          // 5. Tactical Progress Control Panel (Bottom Glassmorphic Card)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildControlPanel(context, systemColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSightCrosshair(Color color) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Stack(
          children: [
            // Top-left corner mark
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: color, width: 3),
                    left: BorderSide(color: color, width: 3),
                  ),
                ),
              ),
            ),
            // Top-right corner mark
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: color, width: 3),
                    right: BorderSide(color: color, width: 3),
                  ),
                ),
              ),
            ),
            // Bottom-left corner mark
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: color, width: 3),
                    left: BorderSide(color: color, width: 3),
                  ),
                ),
              ),
            ),
            // Bottom-right corner mark
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: color, width: 3),
                    right: BorderSide(color: color, width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, Color color) {
    if (_verificationService == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        color: const Color(0xFF03050B).withValues(alpha: 0.8),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Target Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTargetIndicator(
                  Icons.menu_book_rounded,
                  "BOOK (READING)",
                  color,
                ),
                _buildTargetIndicator(
                  Icons.local_cafe_rounded,
                  "CUP (HYDRATION)",
                  color,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live calibration status messages
            ValueListenableBuilder<String>(
              valueListenable: _verificationService!.statusMessage,
              builder: (context, msg, _) {
                return Text(
                  msg,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 12),

            // Holographic sustain progress indicator bar
            ValueListenableBuilder<double>(
              valueListenable: _verificationService!.sustainProgress,
              builder: (context, progress, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Glowing Alarm Accountability Button
            GestureDetector(
              onTap: () {
                if (_isAlarmActive) {
                  _stopAlarm();
                } else {
                  _startAlarm();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isAlarmActive
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isAlarmActive ? Colors.redAccent : Colors.white24,
                    width: 1.5,
                  ),
                  boxShadow: _isAlarmActive
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAlarmActive
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: _isAlarmActive ? Colors.redAccent : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isAlarmActive
                          ? "STOP SIREN"
                          : "ENGAGE ACCOUNTABILITY ALARM",
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: _isAlarmActive
                            ? Colors.redAccent
                            : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetIndicator(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.6), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white60,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
