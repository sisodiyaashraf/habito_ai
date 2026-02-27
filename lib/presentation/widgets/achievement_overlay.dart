import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';

class AchievementOverlay extends StatefulWidget {
  const AchievementOverlay({super.key});

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We listen to HabitProvider to know when to trigger the celebratory uplink
    final habitProvider = context.watch<HabitProvider>();
    final bool triggerCelebration =
        habitProvider.shouldCelebrate || habitProvider.hasLeveledUp;

    if (triggerCelebration) {
      _confettiController.play();

      // Auto-reset flags via Provider to avoid infinite loops
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          habitProvider.resetCelebration();
          habitProvider.resetLevelUp();
        }
      });
    }

    return Stack(
      children: [
        // 1. NEURAL CONFETTI (Custom Neon Palette)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.cyanAccent,
              Colors.purpleAccent,
              Colors.blueAccent,
              Colors.white,
            ],
            gravity: 0.15,
            numberOfParticles: 50, // Denser particles
            emissionFrequency: 0.05,
          ),
        ),

        // 2. BACKDROP & BANNER
        if (triggerCelebration)
          FadeIn(
            duration: const Duration(milliseconds: 300),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: habitProvider.hasLeveledUp
                      ? _buildLevelUpBanner(habitProvider.currentLevel)
                      : _buildStreakBanner(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStreakBanner() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
        decoration: _bannerDecoration(Colors.cyanAccent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flash(
              infinite: true,
              duration: const Duration(seconds: 2),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.cyanAccent,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "STREAK MILESTONE",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "7-DAY SYNC COMPLETE",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            _buildMicroStatus("NEURAL STABILITY OPTIMIZED", Colors.cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelUpBanner(int level) {
    return ZoomIn(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 35),
        decoration: _bannerDecoration(Colors.purpleAccent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.upgrade_rounded,
              color: Colors.purpleAccent,
              size: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              "SYSTEM UPGRADE",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "LEVEL $level REACHED",
              style: const TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.purpleAccent,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 20),
            _buildMicroStatus("NEURAL CAPACITY EXPANDED", Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroStatus(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  BoxDecoration _bannerDecoration(Color glowColor) {
    return BoxDecoration(
      color: const Color(0xFF03050B).withOpacity(0.9),
      borderRadius: BorderRadius.circular(35),
      border: Border.all(color: glowColor.withOpacity(0.8), width: 2),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.4),
          blurRadius: 50,
          spreadRadius: 2,
        ),
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
      ],
    );
  }
}
