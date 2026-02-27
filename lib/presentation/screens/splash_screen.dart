import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

class HabitoSplashScreen extends StatefulWidget {
  final Widget nextScreen; // Dynamic destination passed from main.dart

  const HabitoSplashScreen({super.key, required this.nextScreen});

  @override
  State<HabitoSplashScreen> createState() => _HabitoSplashScreenState();
}

class _HabitoSplashScreenState extends State<HabitoSplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootSequence();
  }

  /// Handles the transition from boot animation to the app's main entry point
  Future<void> _bootSequence() async {
    // Wait for the Lottie animation to reach its peak (approx 4.5 seconds)
    await Future.delayed(const Duration(milliseconds: 4500));

    if (!mounted) return;

    // Execute Cinematic Transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen,
        transitionDuration: const Duration(
          milliseconds: 1200,
        ), // Slower fade for feel
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInCirc,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03050B),
      body: Stack(
        children: [
          // Cyber Grid Layer
          _buildBackgroundGrid(),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. NEURAL CORE: AI Animation
                FadeIn(
                  duration: const Duration(seconds: 2),
                  child: SizedBox(
                    height: 280,
                    child: Lottie.asset(
                      'assets/lottie_animation/ai animation Flow.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. BRANDING
                _buildBrandingText(),

                const SizedBox(height: 10),

                _buildInitializationStatus(),

                const SizedBox(height: 50),

                // 3. BOOT PROGRESS
                _buildProgressBar(),
              ],
            ),
          ),

          // 4. FOOTER VERSIONING
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return Opacity(
      opacity: 0.1,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://www.transparenttextures.com/patterns/carbon-fibre.png',
            ),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingText() {
    return FadeInUp(
      duration: const Duration(seconds: 1),
      child: const Text(
        "HABITO",
        style: TextStyle(
          color: Colors.white,
          fontSize: 42,
          letterSpacing: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Orbitron',
        ),
      ),
    );
  }

  Widget _buildInitializationStatus() {
    return FadeIn(
      delay: const Duration(milliseconds: 1200),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulseDot(), // Reusable blinking pulse dot
          const SizedBox(width: 8),
          const Text(
            "INITIALIZING NEURAL LINK...",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: FadeInUp(
        delay: const Duration(seconds: 2),
        child: const Center(
          child: Text(
            "VERSION 1.0.0+1 | SENTIENT OS",
            style: TextStyle(
              color: Colors.white10,
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper for the blinking cyan pulse in the status row
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(
        Icons.emergency_recording_rounded,
        color: Colors.cyanAccent,
        size: 8,
      ),
    );
  }
}
