import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class MissionSuccessGlitch extends StatelessWidget {
  const MissionSuccessGlitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.cyanAccent.withOpacity(0.1),
      child: Stack(
        children: [
          // Background Noise
          Opacity(
            opacity: 0.1,
            child: Image.asset(
              "assets/images/neural_static.png",
              fit: BoxFit.cover,
              height: double.infinity,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flash(
                  infinite: true,
                  duration: const Duration(milliseconds: 200),
                  child: const Text(
                    "MISSION SECURED",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeInLeft(
                  child: const Text(
                    "SQUADRON SYNC 100% // XP MULTIPLIER ACTIVE",
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.cyanAccent,
                      fontSize: 10,
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
