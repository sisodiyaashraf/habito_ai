import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:provider/provider.dart'; // Using your package
import '../providers/habit_provider.dart';

class DisciplineHeatmap extends StatelessWidget {
  const DisciplineHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
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
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NEURAL UPLINK HISTORY",
            style: TextStyle(
              color: Colors.cyanAccent,
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
            defaultColor: Colors.white.withOpacity(0.05),
            textColor: Colors.white38,
            showColorTip: false,
            scrollable: true,
            size: 25,
            colorsets: {
              1: Colors.cyanAccent.withOpacity(0.2),
              3: Colors.cyanAccent.withOpacity(0.5),
              5: Colors.cyanAccent, // Brighter if more habits are done
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
