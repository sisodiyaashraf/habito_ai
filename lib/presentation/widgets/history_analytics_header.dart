import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class HistoryAnalyticsHeader extends StatelessWidget {
  const HistoryAnalyticsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // 1. Level & XP Progress Section (Primary System Status)
          _buildLevelProgress(provider),
          const SizedBox(height: 16),

          // 2. Stats Row (Neural Metrics)
          Row(
            children: [
              _buildStatTile(
                "TOTAL XP",
                provider.totalXP.toString(),
                Icons.bolt_rounded,
                Colors.cyanAccent,
              ),
              const SizedBox(width: 10),
              _buildStatTile(
                "STREAK",
                "${provider.highestStreak}D",
                Icons.whatshot_rounded,
                Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              _buildStatTile(
                "SYNC",
                "${(provider.averageCompletionRate * 100).toInt()}%",
                Icons.alt_route_rounded,
                Colors.purpleAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(HabitProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04), // Boosted visibility
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SYSTEM LEVEL ${provider.currentLevel}",
                style: const TextStyle(
                  fontFamily: 'Orbitron', // Using headline font
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              Text(
                "${(provider.levelProgress * 100).toInt()}% UPLINK",
                style: TextStyle(
                  fontFamily: 'SpaceMono', // Using console font
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Futuristic Progress Bar
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: provider.levelProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.cyanAccent,
                  ),
                ),
              ),
              // Subtle glow effect under the bar
              if (provider.levelProgress > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Heavier blur
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Orbitron', // Numbers look great in Orbitron
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: color.withOpacity(0.7),
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
