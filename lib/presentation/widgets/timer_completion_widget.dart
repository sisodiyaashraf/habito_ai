import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

class TimerCompletionWidget extends StatelessWidget {
  final VoidCallback onDismiss;

  const TimerCompletionWidget({super.key, required this.onDismiss});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Timer Complete",
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (context, anim1, anim2) {
        return TimerCompletionWidget(
          onDismiss: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(seconds: 1),
              child: Lottie.asset(
                'assets/lottie_animation/ai animation Flow.json',
                width: 350,
                height: 350,
                repeat: false,
              ),
            ),
            const SizedBox(height: 10),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: const Text(
                "MISSION_COMPLETE",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.cyanAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: Colors.cyanAccent, blurRadius: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: const Text(
                "NEURAL_DATA_UPLINKED_SUCCESSFULLY",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            FadeInUp(
              delay: const Duration(milliseconds: 1200),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "INITIALIZE_REWARD_PROTOCOL",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
