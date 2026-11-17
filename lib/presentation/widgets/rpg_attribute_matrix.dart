import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../../domain/entities/rpg_stats.dart';

class RpgAttributeMatrix extends StatelessWidget {
  const RpgAttributeMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitProvider>();
    final RPGStats stats = habit.rpgStats;
    final theme = Theme.of(context);

    final attributes = [
      {
        'label': 'DISCIPLINE',
        'sub': 'Streaks & Apex Priorities',
        'value': stats.discipline,
        'icon': Icons.fitness_center_rounded,
        'color': const Color(0xFFEF4444), // Crimson
      },
      {
        'label': 'FOCUS',
        'sub': 'Deep Work & Timed Sessions',
        'value': stats.focus,
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF38BDF8), // Sky Cyan
      },
      {
        'label': 'VITALITY',
        'sub': 'Fitness, Sports & Recovery',
        'value': stats.vitality,
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFF10B981), // Emerald
      },
      {
        'label': 'WILLPOWER',
        'sub': 'Strain Resistance & Grit',
        'value': stats.willpower,
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFF59E0B), // Amber
      },
      {
        'label': 'NEURAL SYNC',
        'sub': 'System-wide Consistency',
        'value': stats.neuralSync,
        'icon': Icons.hub_rounded,
        'color': const Color(0xFFA855F7), // Purple
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "SENTINEL RPG MATRIX",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "CP ${stats.combatPower}",
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Attributes List
          ...attributes.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final double val = item['value'] as double;
            final Color color = item['color'] as Color;
            final String grade = RPGStats.getGrade(val);
            final Color gradeColor = RPGStats.getGradeColor(grade);

            return FadeInLeft(
              delay: Duration(milliseconds: idx * 70),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(item['icon'] as IconData, color: color, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "• ${item['sub']}",
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 8,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),

                        // Grade & Percent
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: gradeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: gradeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                grade,
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: gradeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${val.toInt()}%",
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (val / 100.0).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
