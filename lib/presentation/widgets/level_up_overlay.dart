import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Use select to only rebuild when hasLeveledUp changes
    final hasLeveledUp = context.select((HabitProvider p) => p.hasLeveledUp);
    final currentLevel = context.select((HabitProvider p) => p.currentLevel);
    final totalXP = context.select((HabitProvider p) => p.totalXP);
    final provider = context.read<HabitProvider>();

    if (!hasLeveledUp) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Background Blur + Darkener
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.9)),
            ),
          ),

          // 2. Invisible Full-Screen Tap-to-Dismiss
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // Ensures clicks anywhere work
              onTap: () {
                debugPrint("Overlay Dismissed via Background");
                provider.resetLevelUp();
              },
            ),
          ),

          // 3. The Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    "NEURAL EVOLUTION DETECTED",
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Geometric Level Reveal
                Flash(
                  duration: const Duration(seconds: 1),
                  child: Column(
                    children: [
                      Text(
                        "LEVEL",
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.cyanAccent.withOpacity(0.4),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                        ),
                      ),
                      Text(
                        "$currentLevel",
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.cyanAccent,
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.cyanAccent.withOpacity(0.8),
                              blurRadius: 50,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      const Text(
                        "PROTOCOL CAPACITY INCREASED",
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "TOTAL_XP: $totalXP // CORE_STABILITY: OPTIMAL",
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            color: Colors.cyanAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // The Button
                FadeIn(
                  delay: const Duration(seconds: 1),
                  child: OutlinedButton(
                    onPressed: () {
                      debugPrint("Button Pressed");
                      provider.resetLevelUp();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.cyanAccent,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      "DISMISS LOG",
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
