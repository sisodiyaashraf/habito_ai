import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class EmptyHabitsView extends StatelessWidget {
  const EmptyHabitsView({super.key});

  @override
  Widget build(BuildContext context) {
    // We use LayoutBuilder to ensure we don't exceed available space
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Animated Icon with Pulsing Effect
                  FadeIn(
                    duration: const Duration(seconds: 2),
                    child: Pulse(
                      infinite: true,
                      child: Icon(
                        Icons.sensors_off_rounded,
                        size: 80,
                        color: Colors.cyanAccent.withOpacity(0.15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Title with Cyber-spacing
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: const Text(
                      "NO NEURAL PROTOCOLS ACTIVE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Subtitle
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: const Text(
                      "Initialize your first habit to begin uplink.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  // Add a small spacer to account for the 120px Nav Bar height
                  // to prevent the icon from appearing "pushed down"
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
