import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../../domain/entities/rpg_stats.dart';
import 'cyber_armory_sheet.dart';

class GamelikeHudBar extends StatelessWidget {
  final VoidCallback? onOpenGameHub;

  const GamelikeHudBar({super.key, this.onOpenGameHub});

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitProvider>();
    final RPGStats stats = habit.rpgStats;
    final theme = Theme.of(context);
    final isOverdrive = habit.isOverdriveActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOverdrive
              ? Colors.amberAccent.withValues(alpha: 0.7)
              : stats.rankColor.withValues(alpha: 0.3),
          width: isOverdrive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdrive
                ? Colors.amberAccent.withValues(alpha: 0.15)
                : stats.rankColor.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // TOP ROW: Operative Rank + Bits & Shields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rank & Level Pill
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stats.rankColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: stats.rankColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(stats.rankBadge, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            "LVL ${habit.currentLevel}",
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: stats.rankColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        stats.rankTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Currency & Power-Ups Pills
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Streak Shield Indicator
                  if (habit.streakShields > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded, color: Colors.lightBlueAccent, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            "${habit.streakShields}",
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Neural Bits (Credits) Pill (Interactive)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      CyberArmorySheet.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyanAccent.withValues(alpha: 0.2),
                            Colors.purpleAccent.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_rounded, color: Colors.cyanAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${habit.neuralCredits}",
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.add, color: Colors.cyanAccent, size: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // MIDDLE ROW: XP Linear Progress Bar with glowing aura
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "XP: ${habit.totalXP % 500} / 500",
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${(habit.levelProgress * 100).toInt()}% READY",
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 8,
                            color: stats.rankColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: habit.levelProgress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(stats.rankColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // BOTTOM ROW: Telemetry Indicators (Streak Flame + Multiplier + Combat Power)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Streak & Multiplier
              Expanded(
                child: Row(
                  children: [
                    Pulse(
                      infinite: true,
                      duration: const Duration(seconds: 2),
                      child: const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${habit.highestStreak}D STREAK",
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOverdrive
                              ? Colors.amberAccent.withValues(alpha: 0.2)
                              : Colors.orangeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOverdrive ? Colors.amberAccent : Colors.orangeAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          isOverdrive ? "⚡ 2X OVERDRIVE" : "${habit.streakMultiplier}X BOOST",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isOverdrive ? Colors.amberAccent : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Combat Power (CP) Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed_rounded, color: Colors.cyanAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      "CP ${stats.combatPower}",
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
