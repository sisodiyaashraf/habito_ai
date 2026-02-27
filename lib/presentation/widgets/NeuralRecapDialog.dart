import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NeuralRecapDialog extends StatelessWidget {
  final String summary;

  const NeuralRecapDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: AlertDialog(
        backgroundColor: const Color(0xFF060912).withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
        ),
        title: Column(
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: Colors.cyanAccent,
              size: 28,
            ),
            const SizedBox(height: 12),
            const Text(
              "DAILY MISSION RECAP",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            summary.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              height: 1.6,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  "ACKNOWLEDGE",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
