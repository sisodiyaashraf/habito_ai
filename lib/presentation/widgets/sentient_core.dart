import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';

class SentientCore extends StatelessWidget {
  const SentientCore({super.key});

  @override
  Widget build(BuildContext context) {
    // Neural Link: Watching providers for state changes
    final habitProvider = context.watch<HabitProvider>();
    final aiProvider = context.watch<AIProvider>();

    final habits = habitProvider.habits;
    final level = habitProvider.currentLevel;

    // Determine Theme Color based on AI Persona
    Color coreColor;
    switch (aiProvider.currentPersona) {
      case AIPersonality.gentle:
        coreColor = Colors.greenAccent;
        break;
      case AIPersonality.brutal:
        coreColor = Colors.redAccent;
        break;
      case AIPersonality.neutral:
      default:
        coreColor = Colors.cyanAccent;
    }

    // Calculate Completion Percentage
    double completionRate = 0;
    if (habits.isNotEmpty) {
      final now = DateTime.now();
      final completedToday = habits
          .where(
            (h) => h.completionDates.any(
              (d) =>
                  d.day == now.day &&
                  d.month == now.month &&
                  d.year == now.year,
            ),
          )
          .length;
      completionRate = completedToday / habits.length;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing Neural Core
        TweenAnimationBuilder(
          // Level increases pulse speed (Duration gets shorter as level rises)
          duration: Duration(
            milliseconds: (1500 / (1 + (level * 0.2))).toInt().clamp(400, 1500),
          ),
          tween: Tween(begin: 0.95, end: 1.05),
          curve: Curves.easeInOutSine,
          // onEnd ensures the animation restarts cleanly without creating "ghost" dependents
          onEnd: () {},
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Neural Glow Layer
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    width: 60 + (level * 2).toDouble(),
                    height: 60 + (level * 2).toDouble(),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: coreColor.withOpacity(
                            0.3 + (completionRate * 0.4), // Boosted opacity
                          ),
                          blurRadius: 20 + (level * 2).toDouble(),
                          spreadRadius: 2 + (completionRate * 12).toDouble(),
                        ),
                      ],
                    ),
                  ),

                  // Lottie Core Animation
                  Lottie.asset(
                    'assets/lottie/ai_core.json',
                    height: 85 + (level.clamp(0, 10) * 2).toDouble(),
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(const [
                          '**',
                          'Fill 1',
                          '**',
                        ], value: coreColor),
                      ],
                    ),
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.blur_on, color: coreColor, size: 45);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // LVL Indicator (Orbitron)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: coreColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: coreColor.withOpacity(0.4), width: 1),
          ),
          child: Text(
            "LVL $level",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: coreColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Sync Metrics (SpaceMono)
        Text(
          "${(completionRate * 100).toInt()}% SYNCED",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white.withOpacity(0.6), // Boosted visibility
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
