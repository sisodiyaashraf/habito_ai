import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/hive_provider.dart';

class HiveActionDialog extends StatelessWidget {
  const HiveActionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: AlertDialog(
        backgroundColor: const Color(0xFF03050B).withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: Colors.cyanAccent.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        title: Column(
          children: [
            const Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 30),
            const SizedBox(height: 12),
            const Text(
              "HIVE UPLINK",
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              label: "INITIALIZE NEW HIVE",
              subLabel: "GENERATE UNIQUE PROTOCOL_ID",
              icon: Icons.add_moderator_rounded,
              onTap: () async {
                HapticFeedback.heavyImpact();
                // 1. Clear focus to prevent assertion errors
                FocusManager.instance.primaryFocus?.unfocus();

                // 2. Trigger Neural Generation
                await context.read<HiveProvider>().initializeNewHive();

                // 3. Close Uplink Dialog
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 15),
            _buildActionButton(
              label: "JOIN EXISTING HIVE",
              subLabel: "SYNC WITH EXTERNAL NODE",
              icon: Icons.sensors_rounded,
              onTap: () {
                HapticFeedback.mediumImpact();
                FocusManager.instance.primaryFocus?.unfocus();

                // Pop current dialog then show Join input
                Navigator.pop(context);
                _showJoinInputDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper for text-input join logic
  void _showJoinInputDialog(BuildContext context) {
    final TextEditingController joinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF03050B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.cyanAccent, width: 0.5),
          ),
          title: const Text(
            "INPUT HIVE_ID",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          content: TextField(
            controller: joinController,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.cyanAccent,
            ),
            decoration: InputDecoration(
              hintText: "HAB-XXXX-2026",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white10),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<HiveProvider>().joinHive(
                  joinController.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text(
                "UPLINK",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.cyanAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subLabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.cyanAccent, size: 22),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subLabel,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
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
