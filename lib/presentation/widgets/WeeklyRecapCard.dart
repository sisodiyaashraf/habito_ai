import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';

class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final hiveProvider = context.watch<HiveProvider>();
    final analysis = habitProvider.weeklyPeakAnalysis;

    final Color themeColor = hiveProvider.hiveStability < 0.3
        ? Colors.redAccent
        : Colors.cyanAccent;

    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: themeColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatItem(
                  "PEAK SYNC",
                  analysis['day'],
                  Icons.bolt_rounded,
                  themeColor,
                ),
                Container(width: 1, height: 40, color: Colors.white10),
                _buildStatItem(
                  "STABILITY",
                  "${(analysis['score'] * 100).toInt()}%",
                  Icons.auto_graph_rounded,
                  themeColor,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInsightBar(themeColor, analysis['score']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color theme,
  ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: theme.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white38,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBar(Color theme, double score) {
    String message = score > 0.8
        ? "NEURAL OVERDRIVE DETECTED"
        : "SYSTEM STABILIZING";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: theme.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Pulse(child: Icon(Icons.shield_rounded, color: theme, size: 14)),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: theme,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
