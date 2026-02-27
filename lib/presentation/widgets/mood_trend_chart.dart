import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class MoodTrendChart extends StatelessWidget {
  const MoodTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;

    // Extract weekly data (Mock logic provided below)
    List<double> moodScores = _getWeeklyMoodTrend(habits);

    return Container(
      height: 120, // Slightly taller for better resolution
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04), // Boosted visibility
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (SpaceMono)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NEURAL STABILITY (7D)",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(
                Icons.query_stats_rounded,
                color: Colors.cyanAccent,
                size: 12,
              ),
            ],
          ),
          const Spacer(),
          // The Neural Bars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: moodScores.map((score) => _buildMoodBar(score)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBar(double score) {
    // Score is 1-5. Map to heights 15-50 for a dramatic "HUD" look.
    double barHeight = (score * 8) + 10;
    Color statusColor = _getMoodColor(score);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 14,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [statusColor, statusColor.withOpacity(0.2)],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Small indicator dot beneath
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Color _getMoodColor(double score) {
    if (score >= 4.0) return Colors.greenAccent;
    if (score <= 2.5) return Colors.redAccent;
    return Colors.cyanAccent;
  }

  List<double> _getWeeklyMoodTrend(List<dynamic> habits) {
    // In a real scenario, you'd aggregate provider.habits.dailyMood entries
    // For now, this represents the 7-day stability trend.
    return [3.0, 4.5, 2.0, 5.0, 3.8, 4.2, 3.5];
  }
}
