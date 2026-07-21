import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NEURAL ACTIVITY_LOG",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                fontSize: 8,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'MON',
                            'TUE',
                            'WED',
                            'THU',
                            'FRI',
                            'SAT',
                            'SUN',
                          ];
                          if (value.toInt() >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    7,
                    (i) => _makeGroupData(i, (i % 5 + 1).toDouble(), theme),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    // Intensity mapping for neon glow
    final Color barColor = y >= 4
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.4);

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          // Neural Glow Shadow
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [barColor.withValues(alpha: 0.1), barColor],
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 5,
            color: isDark ? Colors.white.withValues(alpha: 0.03) : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          ),
        ),
      ],
    );
  }
}
