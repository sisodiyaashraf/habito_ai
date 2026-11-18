import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../../domain/entities/bounty_quest.dart';

class BountyBoardWidget extends StatelessWidget {
  const BountyBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitProvider>();
    final List<BountyQuest> quests = habit.dailyQuests;
    final theme = Theme.of(context);

    final completedCount = quests.where((q) => q.isCompleted).length;

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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "DAILY TACTICAL BOUNTIES",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "$completedCount / ${quests.length} CLEARED",
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quests List
          ...quests.asMap().entries.map((entry) {
            final idx = entry.key;
            final quest = entry.value;

            return FadeInUp(
              delay: Duration(milliseconds: idx * 60),
              child: _buildQuestCard(context, quest, habit, theme),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context,
    BountyQuest quest,
    HabitProvider habit,
    ThemeData theme,
  ) {
    final bool canClaim = quest.isCompleted && !quest.isClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quest.isClaimed
            ? theme.colorScheme.onSurface.withValues(alpha: 0.02)
            : (canClaim
                ? Colors.cyanAccent.withValues(alpha: 0.05)
                : theme.colorScheme.surface.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: canClaim
              ? Colors.cyanAccent.withValues(alpha: 0.5)
              : (quest.isClaimed
                  ? Colors.greenAccent.withValues(alpha: 0.2)
                  : theme.colorScheme.outline.withValues(alpha: 0.25)),
          width: canClaim ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Quest Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: quest.isClaimed
                  ? Colors.greenAccent.withValues(alpha: 0.1)
                  : (canClaim
                      ? Colors.cyanAccent.withValues(alpha: 0.15)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05)),
            ),
            child: Icon(
              quest.isClaimed ? Icons.check_circle_rounded : quest.icon,
              color: quest.isClaimed
                  ? Colors.greenAccent
                  : (canClaim ? Colors.cyanAccent : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Quest Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: quest.isClaimed
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${quest.currentProgress} / ${quest.targetProgress}",
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: canClaim ? Colors.cyanAccent : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  quest.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 8,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                // Rewards tags & Progress Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "+${quest.xpReward} XP",
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "+${quest.creditsReward} BITS",
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: quest.progressRatio,
                          minHeight: 4,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            quest.isClaimed ? Colors.greenAccent : Colors.cyanAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Action / Claim Button
          if (canClaim)
            Pulse(
              infinite: true,
              duration: const Duration(seconds: 1),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  habit.claimBounty(quest.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: Colors.cyanAccent.withValues(alpha: 0.5),
                ),
                child: const Text(
                  "CLAIM",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else if (quest.isClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "DONE",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
