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
          _buildLevelProgress(context, provider),
          const SizedBox(height: 16),

          // 2. Stats Row (Neural Metrics)
          Row(
            children: [
              _buildStatTile(
                "XP",
                provider.totalXP.toString(),
                Icons.bolt_rounded,
                Colors.cyanAccent,
              ),
              const SizedBox(width: 6),
              _buildStatTile(
                "STREAK",
                "${provider.highestStreak}D",
                Icons.whatshot_rounded,
                Colors.orangeAccent,
              ),
              const SizedBox(width: 6),
              _buildStatTile(
                "SYNC",
                "${(provider.averageCompletionRate * 100).toInt()}%",
                Icons.alt_route_rounded,
                Colors.purpleAccent,
              ),
              const SizedBox(width: 6),
              _buildStatTile(
                "BYPASSED",
                "${provider.habits.fold(0, (sum, h) => sum + h.totalTerminated)}",
                Icons.cancel_outlined,
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, HabitProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.04) 
            : theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.12) 
              : theme.colorScheme.outline.withValues(alpha: 0.5),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SYSTEM LEVEL ${provider.currentLevel}",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              Text(
                "${(provider.levelProgress * 100).toInt()}% UPLINK",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
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
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.06) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? color.withValues(alpha: 0.2) : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: isDark ? color.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
