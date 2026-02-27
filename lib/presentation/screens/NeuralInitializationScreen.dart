import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

class NeuralInitializationScreen extends StatefulWidget {
  const NeuralInitializationScreen({super.key});

  @override
  State<NeuralInitializationScreen> createState() =>
      _NeuralInitializationScreenState();
}

class _NeuralInitializationScreenState extends State<NeuralInitializationScreen>
    with WidgetsBindingObserver {
  final _dndPlugin = DoNotDisturbPlugin();

  bool _isNotificationsDone = false;
  bool _isDndDone = false;
  bool _isBootDone = false;
  bool _isInitializing = false;
  double _loadProgress = 0.0;
  String _consoleLog = "AWAITING COMMAND...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitializing) {
      _checkPermissionsSilently();
    }
  }

  Future<void> _checkPermissionsSilently() async {
    bool isAllowed = await _dndPlugin.isNotificationPolicyAccessGranted();
    if (isAllowed) {
      setState(() {
        _isDndDone = true;
        _loadProgress = 0.66;
        _consoleLog = "GHOST_MODE_PROTOCOL: AUTHORIZED";
      });
      if (_isNotificationsDone) _finalizeBoot();
    } else {
      setState(() => _consoleLog = "PROTOCOL_REJECTED: ACCESS DENIED");
    }
  }

  Future<void> _initializeSystem() async {
    setState(() {
      _isInitializing = true;
      _consoleLog = "INITIALIZING CORE UPLINK...";
      _loadProgress = 0.1;
    });
    HapticFeedback.mediumImpact();

    // 1. Request Notifications
    final status = await Permission.notification.request();
    setState(() {
      _isNotificationsDone = status.isGranted;
      _loadProgress = 0.33;
      _consoleLog = status.isGranted
          ? "NOTIFICATIONS: ENABLED"
          : "NOTIFICATIONS: DENIED";
    });

    // 2. Request DND Access
    bool isDndAllowed = await _dndPlugin.isNotificationPolicyAccessGranted();

    if (!isDndAllowed) {
      setState(() => _consoleLog = "REDIRECTING TO SYSTEM PERMISSIONS...");
      await _dndPlugin.openNotificationPolicyAccessSettings();
    } else {
      setState(() {
        _isDndDone = true;
        _loadProgress = 0.66;
        _consoleLog = "PERMISSIONS VERIFIED.";
      });
      if (_isNotificationsDone) _finalizeBoot();
    }
  }

  Future<void> _finalizeBoot() async {
    if (_isBootDone) return;

    setState(() {
      _consoleLog = "ESTABLISHING NEURAL SYNC...";
      _loadProgress = 0.85;
    });

    // --- THE NEURAL PULSE SEQUENCE ---
    // Incremental Haptic feedback
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(milliseconds: 100 - (i * 10)));
      HapticFeedback.lightImpact();
    }

    setState(() {
      _consoleLog = "SYNC_COMPLETE: SENTINEL VERIFIED";
      _loadProgress = 1.0;
    });

    HapticFeedback.heavyImpact();
    setState(() => _isBootDone = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, anim, secondAnim) => const HomeScreen(),
          transitionsBuilder: (context, anim, secondAnim, child) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.2, end: 1.0).animate(anim),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03050B),
      body: Stack(
        children: [
          _buildAmbientGlow(),
          _buildScanningLines(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Text(
                      "CORE INITIALIZATION",
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.9),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        fontSize: 22, // Increased for visibility
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: const Text(
                      "Establishing neural link. Grant hardware permissions to synchronize the OS.",
                      style: TextStyle(
                        color: Colors.white70, // Higher contrast
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  _buildProgressBar(),
                  const SizedBox(height: 40),

                  _buildStatusLine(
                    "UPLINK: NOTIFICATIONS",
                    _isNotificationsDone,
                  ),
                  _buildStatusLine("PROTOCOL: GHOST_MODE", _isDndDone),
                  _buildStatusLine("SYSTEM: NEURAL_BOOT", _isBootDone),

                  const SizedBox(height: 60),

                  if (!_isBootDone) Center(child: _buildInitializationButton()),

                  const SizedBox(height: 40),
                  _buildConsole(),
                ],
              ),
            ),
          ),

          // THE NEURAL PULSE OVERLAY
          if (_isBootDone)
            FadeIn(
              duration: const Duration(milliseconds: 150),
              child: Container(
                color: Colors.cyanAccent.withOpacity(0.08),
                child: Center(
                  child: Flash(
                    duration: const Duration(milliseconds: 600),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.cyanAccent,
                      size: 100,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "SYNC STATUS",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${(_loadProgress * 100).toInt()}%",
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _loadProgress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitializationButton() {
    return FadeInUp(
      child: GestureDetector(
        onTap: _isInitializing ? null : _initializeSystem,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: _isInitializing
                  ? [Colors.white10, Colors.white10]
                  : [
                      Colors.cyanAccent.withOpacity(0.3),
                      Colors.cyanAccent.withOpacity(0.05),
                    ],
            ),
            border: Border.all(
              color: _isInitializing ? Colors.white24 : Colors.cyanAccent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _isInitializing ? "SYNCHRONIZING..." : "START INITIALIZATION",
              style: TextStyle(
                color: _isInitializing ? Colors.white38 : Colors.cyanAccent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 4,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLine(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? Colors.cyanAccent : Colors.transparent,
              border: Border.all(
                color: isDone ? Colors.cyanAccent : Colors.white24,
                width: 2,
              ),
              boxShadow: isDone
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ]
                  : [],
            ),
            child: isDone
                ? const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 12,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          ),
          const SizedBox(width: 25),
          Text(
            label,
            style: TextStyle(
              color: isDone ? Colors.white : Colors.white38,
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsole() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black45,
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Text(
              ">",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _consoleLog,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningLines() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.1,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                "https://www.transparenttextures.com/patterns/carbon-fibre.png",
              ),
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return Positioned(
      top: -100,
      left: -100,
      child: Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.07),
              blurRadius: 200,
              spreadRadius: 100,
            ),
          ],
        ),
      ),
    );
  }
}
