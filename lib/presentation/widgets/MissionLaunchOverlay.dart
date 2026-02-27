import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/hive_provider.dart';

class MissionLaunchOverlay extends StatelessWidget {
  final String goal;

  const MissionLaunchOverlay({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Pulsing Warning Icon
            Flash(
              infinite: true,
              child: const Icon(
                Icons.rocket_launch,
                color: Colors.cyanAccent,
                size: 80,
              ),
            ),
            const SizedBox(height: 30),

            // 2. Glitchy Mission Text
            FadeInDown(
              child: Text(
                "MISSION DISPATCHED",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. The Objective (SpaceMono)
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10),
                  color: Colors.white.withOpacity(0.02),
                ),
                child: Text(
                  "> OBJECTIVE: ${goal.toUpperCase()}",
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // 4. Initialization Bar
            Container(
              width: 200,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Colors.cyanAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
