import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../providers/habit_provider.dart';
import 'persona_selector.dart';

class AIInsightCard extends StatelessWidget {
  const AIInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final aiProvider = context.watch<AIProvider>();

    // Detect Multiplier state for UI enhancement
    final bool hasStreakBonus = habitProvider.streakMultiplier > 1.0;

    Color themeColor;
    switch (aiProvider.currentPersona) {
      case AIPersonality.gentle:
        themeColor = Colors.greenAccent;
        break;
      case AIPersonality.brutal:
        themeColor = Colors.redAccent;
        break;
      case AIPersonality.neutral:
      default:
        // Switch to Cyan if bonus is active, else stay default
        themeColor = hasStreakBonus
            ? Colors.cyanAccent
            : const Color(0xFF64FFDA);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: hasStreakBonus ? themeColor : themeColor.withOpacity(0.25),
              width: hasStreakBonus ? 1.5 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor.withOpacity(hasStreakBonus ? 0.15 : 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TERMINAL HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPulseDot(themeColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NEURAL ADVISOR v2.0",
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: themeColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "LEVEL ${habitProvider.currentLevel} PROTOCOL // STREAK: ${habitProvider.highestStreak}",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (aiProvider.isLoading)
                    const _BlinkingTerminalCursor()
                  else if (hasStreakBonus)
                    _buildMultiplierBadge(
                      habitProvider.streakMultiplier,
                      themeColor,
                    )
                  else
                    Icon(Icons.bolt_rounded, color: themeColor, size: 14),
                ],
              ),
              const SizedBox(height: 25),

              // --- AI RESPONSE TERMINAL ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: themeColor.withOpacity(0.1)),
                ),
                child: aiProvider.isLoading
                    ? _buildLoadingShimmer()
                    : TweenAnimationBuilder(
                        key: ValueKey(aiProvider.aiResponse),
                        duration: const Duration(milliseconds: 1500),
                        tween: IntTween(
                          begin: 0,
                          end: aiProvider.aiResponse.length,
                        ),
                        builder: (context, int value, child) {
                          return Text(
                            aiProvider.aiResponse
                                .substring(0, value)
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 12,
                              height: 1.6,
                              fontFamily: 'SpaceMono',
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: themeColor.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),
              const PersonaSelector(),
              const SizedBox(height: 24),

              // --- NEURAL PROGRESS & MULTIPLIER STATS ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CORE_XP: ${habitProvider.totalXP}",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(habitProvider.levelProgress * 100).toInt()}% EVOLUTION",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: themeColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: habitProvider.levelProgress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- ACTION ROW ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasStreakBonus)
                    Text(
                      "» SYSTEM EFFICIENCY: ${habitProvider.streakMultiplier}x",
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: themeColor.withOpacity(0.8),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const SizedBox(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      aiProvider.fetchFeedback(
                        habits: habitProvider.habits,
                        currentLevel: habitProvider.currentLevel,
                        totalXP: habitProvider.totalXP,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: themeColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_alt_rounded,
                            size: 14,
                            color: themeColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "RE-SYNC",
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: themeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildMultiplierBadge(double multiplier, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "${multiplier}x BOOST",
        style: TextStyle(
          fontFamily: 'Orbitron',
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPulseDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            width: index == 2 ? 150 : double.infinity,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlinkingTerminalCursor extends StatefulWidget {
  const _BlinkingTerminalCursor();

  @override
  State<_BlinkingTerminalCursor> createState() =>
      _BlinkingTerminalCursorState();
}

class _BlinkingTerminalCursorState extends State<_BlinkingTerminalCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 8, height: 14, color: Colors.white24),
    );
  }
}
