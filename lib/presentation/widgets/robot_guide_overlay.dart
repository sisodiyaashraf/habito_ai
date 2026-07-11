import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class RobotGuideOverlay extends StatelessWidget {
  final String message;
  final String label;
  final VoidCallback onDismiss;

  const RobotGuideOverlay({
    super.key,
    required this.message,
    required this.label,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // 1. LOCK THE ENTIRE UI GROUP
      // This is the main anchor. Do not change these values between screens.
      bottom: 100,
      left: 15,
      right: 15,
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Stack(
          clipBehavior: Clip.none, // Essential to let the robot float "outside"
          children: [
            // --- 1. THE MAIN SPEECH BUBBLE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 15),
              margin: const EdgeInsets.only(
                top: 35,
              ), // Space for the robot to sit on top
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onDismiss,
                      child: Pulse(
                        infinite: true,
                        duration: const Duration(seconds: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE67E22).withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            "NEXT ➔",
                            style: TextStyle(
                              color: Color(0xFFE67E22),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. FIXED ROBOT PLACEMENT ---
            // We use 'top' with a negative value to "stick" it to the bubble
            // This prevents it from jumping when screen height changes.
            Positioned(
              top: -21, // Anchored to the top of the Stack
              right: 10,
              child: Image.asset(
                'assets/robots/robotguide2.png',
                height: 90, // Slightly larger for better presence
                fit: BoxFit.contain,
              ),
            ),

            // --- 3. THE ROUNDED LABEL TAG ---
            Positioned(
              top: 22, // Sitting perfectly on the top edge of the white bubble
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE67E22).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
