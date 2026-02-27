import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class FuturisticNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const FuturisticNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    // Dynamic Daily Progress Logic
    double dailyProgress = 0.0;
    if (provider.habits.isNotEmpty) {
      final doneCount = provider.habits
          .where((h) => h.isGoalMet(DateTime.now()))
          .length;
      dailyProgress = (doneCount / provider.habits.length).clamp(0.0, 1.0);
    }

    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glassmorphic Nav Base
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // LEFT WING: Core Utilities
                    _buildNavItem(
                      icon: Icons.grid_view_rounded,
                      label: "CORE",
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: "VAULT",
                      index: 1,
                    ),

                    // CENTRAL HUB SPACER (Width matched to Floating Button)
                    const SizedBox(width: 70),

                    // RIGHT WING: Essential Squad & Identity Features
                    // Index 4: Social Hive Coordination
                    _buildNavItem(
                      icon: Icons.groups_2_outlined,
                      label: "SQUAD",
                      index: 4,
                    ),

                    // Index 3: Personal Dossier
                    _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      label: "DOSSIER",
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // THE CENTRAL GAME HUB BUTTON (Index 2)
          Positioned(
            bottom: 15,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                onItemSelected(2);
              },
              child: _buildCentralHub(dailyProgress, selectedIndex == 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralHub(double progress, bool isActive) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF060912),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? Colors.cyanAccent.withOpacity(0.4)
                : Colors.black.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            Pulse(
              infinite: true,
              child: Opacity(
                opacity: 0.1,
                child: const Icon(
                  Icons.circle,
                  color: Colors.cyanAccent,
                  size: 65,
                ),
              ),
            ),
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                isActive
                    ? Colors.cyanAccent
                    : Colors.cyanAccent.withOpacity(0.4),
              ),
            ),
          ),
          Icon(
            Icons.auto_awesome_motion_rounded,
            color: isActive ? Colors.cyanAccent : Colors.white38,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onItemSelected(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.cyanAccent
                  : Colors.white.withOpacity(0.4),
              size: 22,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.cyanAccent
                    : Colors.white.withOpacity(0.4),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
