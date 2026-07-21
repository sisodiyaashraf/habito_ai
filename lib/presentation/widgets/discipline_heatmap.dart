import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:provider/provider.dart'; // Using your package
import '../providers/habit_provider.dart';

class DisciplineHeatmap extends StatelessWidget {
  const DisciplineHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habits = context.watch<HabitProvider>().habits;

    // Aggregate all completion dates across all habits
    final Map<DateTime, int> dataset = {};
    for (var habit in habits) {
      for (var date in habit.completionDates) {
        // Normalize date to remove time
        final day = DateTime(date.year, date.month, date.day);
        dataset[day] = (dataset[day] ?? 0) + 1;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "NEURAL UPLINK HISTORY",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          // Using the Heatmap component from flutter_calendars
          HeatMap(
            datasets: dataset,
            colorMode: ColorMode.opacity,
            defaultColor: isDark 
                ? Colors.white.withValues(alpha: 0.05) 
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            textColor: isDark ? Colors.white38 : theme.colorScheme.onSurfaceVariant,
            showColorTip: false,
            scrollable: true,
            size: 25,
            colorsets: {
              1: theme.colorScheme.primary.withValues(alpha: 0.2),
              3: theme.colorScheme.primary.withValues(alpha: 0.5),
              5: theme.colorScheme.primary, // Brighter if more habits are done
            },
            onClick: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "$value protocols completed on this solar cycle",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
