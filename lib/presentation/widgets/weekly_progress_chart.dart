import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';

class WeeklyProgressChart extends StatelessWidget {
  const WeeklyProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final hiveProvider = context.watch<HiveProvider>();
    final habits = habitProvider.habits;

    final Color themeColor = hiveProvider.hiveStability < 0.3
        ? Colors.redAccent
        : Colors.cyanAccent;

    final last7Days = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // Keep height fixed to prevent Column/Scrollview conflicts
      height: 240,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: isDark ? 0.5 : 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: themeColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, themeColor, habitProvider),
          const SizedBox(height: 25),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 1.0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: _buildTitles(context, last7Days, themeColor),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(last7Days, habits),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: themeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: index == 6 ? 4 : 2,
                            color: index == 6
                                ? themeColor
                                : theme.scaffoldBackgroundColor,
                            strokeWidth: 2,
                            strokeColor: themeColor,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          themeColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: _buildTouchData(context, themeColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots(List<DateTime> days, List<dynamic> habits) {
    return List.generate(7, (i) {
      final day = days[i];
      if (habits.isEmpty) return FlSpot(i.toDouble(), 0);

      double sum = 0;
      for (var h in habits) {
        // Use your habit's historical data method here
        sum += h.isGoalMet(day) ? 1.0 : 0.0;
      }
      return FlSpot(i.toDouble(), (sum / habits.length).clamp(0.0, 1.0));
    });
  }

  FlTitlesData _buildTitles(BuildContext context, List<DateTime> days, Color themeColor) {
    final theme = Theme.of(context);
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= 7) return const SizedBox();
            final date = days[index];
            final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
            return Text(
              labels[date.weekday - 1],
              style: TextStyle(
                color: _isToday(date) ? themeColor : theme.colorScheme.onSurface.withValues(alpha: 0.24),
                fontSize: 10,
                fontFamily: 'SpaceMono',
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color themeColor, HabitProvider provider) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "STABILITY_LOG",
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
        Icon(
          Icons.query_stats_rounded,
          color: themeColor.withValues(alpha: 0.5),
          size: 14,
        ),
      ],
    );
  }

  LineTouchData _buildTouchData(BuildContext context, Color themeColor) {
    final theme = Theme.of(context);
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => theme.brightness == Brightness.dark ? const Color(0xFF1C1F2B) : Colors.white,
        getTooltipItems: (spots) => spots
            .map(
              (s) => LineTooltipItem(
                "${(s.y * 100).toInt()}% SYNC",
                TextStyle(
                  color: themeColor,
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  bool _isToday(DateTime date) =>
      date.day == DateTime.now().day && date.month == DateTime.now().month;
}
