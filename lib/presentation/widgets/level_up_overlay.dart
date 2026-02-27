import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    // Only trigger if the hasLeveledUp flag is active
    if (!provider.hasLeveledUp) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => provider.resetLevelUp(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 1. Full-screen isolation blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.9)),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // System Notification (SpaceMono)
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

                  // The Main Level Reveal (Orbitron)
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
                          "${provider.currentLevel}",
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: Colors.cyanAccent,
                            fontSize: 120, // Maximum geometric impact
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.cyanAccent.withOpacity(0.8),
                                blurRadius: 50,
                              ),
                              Shadow(
                                color: Colors.cyanAccent.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // System Status Update
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
                        // Technical Log (SpaceMono)
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
                            "TOTAL_XP: ${provider.totalXP} // CORE_STABILITY: OPTIMAL",
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

                  // Call to Action (Orbitron)
                  FadeIn(
                    delay: const Duration(seconds: 1),
                    child: OutlinedButton(
                      onPressed: () => provider.resetLevelUp(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.cyanAccent,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            0,
                          ), // Sharp edges for sci-fi look
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
      ),
    );
  }
}
