import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../domain/entities/habit.dart';
import '../providers/habit_provider.dart';
import 'timer_completion_widget.dart';
import 'neural_timer.dart';

class SessionSheet extends StatefulWidget {
  final Habit habit;
  const SessionSheet({super.key, required this.habit});

  @override
  State<SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<SessionSheet> {
  late int _selectedMood;
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {
      'icon': Icons.sentiment_very_dissatisfied,
      'label': 'CRITICAL',
      'color': Colors.redAccent,
    },
    {
      'icon': Icons.sentiment_dissatisfied,
      'label': 'UNSTABLE',
      'color': Colors.orangeAccent,
    },
    {
      'icon': Icons.sentiment_neutral,
      'label': 'NEUTRAL',
      'color': Colors.amberAccent,
    },
    {
      'icon': Icons.sentiment_satisfied,
      'label': 'OPTIMAL',
      'color': Colors.lightGreenAccent,
    },
    {
      'icon': Icons.sentiment_very_satisfied,
      'label': 'PEAK',
      'color': Colors.cyanAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMood = 3;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlow(theme.colorScheme.primary.withValues(alpha: 0.05), 300),
          ),

          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Column(
                  children: [
                    _buildDragHandle(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildHeader(context),
                            const SizedBox(height: 40),

                            // Immersive Timer Section
                            FadeInDown(
                              duration: const Duration(milliseconds: 800),
                              child: NeuralTimer(
                                habitName: widget.habit.name,
                                isReverse: widget.habit.isTimerEnabled,
                                targetMinutes: widget.habit.timerMinutes ?? 25,
                                onComplete: () {
                                  HapticFeedback.vibrate();
                                  final habitProvider = context.read<HabitProvider>();
                                  
                                  // 1. Show custom animation
                                  TimerCompletionWidget.show(context);
                                  
                                  // 2. Save progress (Mark as completed for today)
                                  habitProvider.toggleHabit(widget.habit.id, context);
                                },
                              ),
                            ),

                            const SizedBox(height: 45),

                            // Mood Module
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: _buildMoodSection(context),
                            ),

                            const SizedBox(height: 40),

                            // Reflection Module
                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              child: _buildReflectionInput(context),
                            ),

                            const SizedBox(
                              height: 120,
                            ), // Bottom spacing for FAB/Nav
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Action Button
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _buildSyncButton(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 32),
            Row(
              children: [
                Pulse(
                  infinite: true,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "NEURAL_SYNC_MODE_v2.0",
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDeleteInSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          widget.habit.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: theme.colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteInSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text(
              "PURGE PROTOCOL",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Text(
          "Permanently purge '${widget.habit.name.toUpperCase()}' from local neural storage? This action cannot be reversed.",
          style: const TextStyle(fontFamily: 'SpaceMono', color: Colors.white70, fontSize: 10),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: const Text("ABORT", style: TextStyle(fontFamily: 'SpaceMono', color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(diagContext);
              Navigator.pop(context);
              context.read<HabitProvider>().deleteHabit(widget.habit.id);
            },
            child: const Text("PURGE DATA", style: TextStyle(fontFamily: 'Orbitron', color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 14,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              "COGNITIVE_VIBE_CHECK",
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_moods.length, (index) {
            bool isSelected = _selectedMood == index + 1;
            final mood = _moods[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedMood = index + 1);
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    padding: EdgeInsets.all(isSelected ? 16 : 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (mood['color'] as Color).withValues(alpha: 0.15)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (mood['color'] as Color)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (mood['color'] as Color).withValues(alpha: 
                                  0.2,
                                ),
                                blurRadius: 15,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      mood['icon'] as IconData,
                      color: isSelected
                          ? (mood['color'] as Color)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      size: isSelected ? 32 : 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Text(
                      mood['label'] as String,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: mood['color'] as Color,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReflectionInput(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.terminal_rounded,
              size: 14,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              "NEURAL_LOG_ENTRY",
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: _noteController,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
            maxLines: 4,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(24),
              hintText: "// RECORD SYSTEM REFLECTION...",
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _syncAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_rounded, size: 22),
                SizedBox(width: 12),
                Text(
                  "FINALIZE PROTOCOL",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _terminateProtocol,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                SizedBox(width: 10),
                Text(
                  "TERMINATE / IGNORE PROTOCOL",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _syncAllData() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final String habitId = widget.habit.id;

    HapticFeedback.heavyImpact();
    await habitProvider.logReflection(
      habitId,
      _noteController.text,
      _selectedMood,
    );

    if (!mounted) return;
    await habitProvider.toggleHabit(habitId, context);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _terminateProtocol() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final String habitId = widget.habit.id;

    HapticFeedback.vibrate();
    if (!mounted) return;
    await habitProvider.ignoreOrTerminateHabit(habitId, context);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildGlow(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4),
      ],
    ),
  );
}
