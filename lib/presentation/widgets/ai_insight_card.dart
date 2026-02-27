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
        themeColor = Colors.cyanAccent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Increased opacity slightly for better card definition
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: themeColor.withOpacity(0.25), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [themeColor.withOpacity(0.08), Colors.transparent],
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
                              fontFamily:
                                  'Orbitron', // Using your headline font
                              color:
                                  themeColor, // Full opacity for primary label
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "LEVEL ${habitProvider.currentLevel} PROTOCOL",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              color: Colors.white.withOpacity(
                                0.5,
                              ), // Increased visibility
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
                  color: Colors.black.withOpacity(
                    0.4,
                  ), // Darker for text contrast
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
                              color: Colors.white.withOpacity(
                                0.95,
                              ), // High visibility
                              fontSize: 12,
                              height: 1.6,
                              fontFamily: 'SpaceMono', // Your terminal font
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

              // --- NEURAL PROGRESS BAR ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "SYNC XP: ${habitProvider.totalXP}",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: Colors.white.withOpacity(
                            0.7,
                          ), // Increased visibility
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(habitProvider.levelProgress * 100).toInt()}% TO LEVEL UP",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: themeColor, // Brighter color
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                            "FORCE RE-SYNC",
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

  // Keep your existing _buildPulseDot, _buildLoadingShimmer, and _BlinkingTerminalCursor

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

// Internal widget for that blinking "system active" cursor
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
