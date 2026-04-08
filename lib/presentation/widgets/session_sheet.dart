import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';
import 'neural_timer.dart'; // Ensure this matches your timer widget file

class SessionSheet extends StatefulWidget {
  final Habit habit;
  const SessionSheet({super.key, required this.habit});

  @override
  State<SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<SessionSheet> {
  late int _selectedMood;
  late double _currentValue;
  final TextEditingController _noteController = TextEditingController();

  final List<IconData> _moodIcons = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  @override
  void initState() {
    super.initState();
    _selectedMood = 3;
    _currentValue = widget.habit.currentValue;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E21).withOpacity(0.85),
            border: const Border(
              top: BorderSide(color: Colors.cyanAccent, width: 0.5),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 30),

                // Timer Module (Handles Reverse if habit is timer-based)
                NeuralTimer(
                  habitName: widget.habit.name,
                  isReverse: widget.habit.isTimerEnabled,
                  targetMinutes: widget.habit.timerMinutes ?? 25,
                  onComplete: () {
                    HapticFeedback.vibrate();
                    // Optional: Auto-increment progress or mood prompt
                  },
                ),

                const SizedBox(height: 30),

                if (widget.habit.unit != "units") ...[
                  _buildProgressSection(),
                  const SizedBox(height: 30),
                ],

                _buildMoodSection(),
                const SizedBox(height: 30),

                _buildReflectionInput(),
                const SizedBox(height: 40),

                _buildSyncButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildHeader() {
    final provider = context.watch<HabitProvider>();
    final double multiplier = provider.streakMultiplier;
    final bool hasBonus = multiplier > 1.0;

    return Column(
      children: [
        Text(
          "PROTOCOL: ${widget.habit.name.toUpperCase()}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: hasBonus
                ? Colors.cyanAccent.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt,
                color: hasBonus ? Colors.cyanAccent : Colors.amberAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                hasBonus
                    ? "NEURAL STREAK: ${multiplier}x XP"
                    : "STANDARD UPLINK: +50 XP",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: hasBonus
                      ? Colors.cyanAccent
                      : Colors.amberAccent.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    bool isComplete = _currentValue >= widget.habit.dailyTarget;
    Color accent = isComplete ? Colors.greenAccent : Colors.cyanAccent;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "INTAKE_LEVEL",
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
              ),
            ),
            Text(
              "${_currentValue.toInt()} / ${widget.habit.dailyTarget} ${widget.habit.unit}",
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: _currentValue,
            max: widget.habit.dailyTarget.toDouble(),
            activeColor: accent,
            inactiveColor: Colors.white10,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _currentValue = val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      children: [
        Text(
          "NEURAL STATE SYNC",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white.withOpacity(0.4),
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            bool isSelected = _selectedMood == index + 1;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedMood = index + 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.cyanAccent.withOpacity(0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.cyanAccent
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Icon(
                  _moodIcons[index],
                  color: isSelected ? Colors.cyanAccent : Colors.white24,
                  size: 26,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReflectionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: _noteController,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          color: Colors.white,
          fontSize: 13,
        ),
        maxLines: 2,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(20),
          hintText: "DATA REFLECTION...",
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 11,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    bool isTargetMet = _currentValue >= widget.habit.dailyTarget;

    return Container(
      decoration: BoxDecoration(
        boxShadow: isTargetMet
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _syncAllData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Text(
          "COMPLETE UPLINK",
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  void _syncAllData() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final scaffoldContext = context;

    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    bool wasCompletedToday = widget.habit.completionDates.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
    bool hitsTargetNow = _currentValue >= widget.habit.dailyTarget;

    // Persist logs
    habitProvider.logReflection(
      widget.habit.id,
      _noteController.text,
      _selectedMood,
    );
    habitProvider.addXP(50);
    HapticFeedback.heavyImpact();

    Navigator.of(context).pop();

    // Delay for UI smoothness
    await Future.delayed(const Duration(milliseconds: 350));

    if (scaffoldContext.mounted) {
      if (hitsTargetNow && !wasCompletedToday) {
        // Trigger completion & Reward Card
        habitProvider.toggleHabit(widget.habit.id, scaffoldContext);
      } else if (_currentValue != widget.habit.currentValue) {
        // Just update progress
        habitProvider.updateHabitProgress(
          widget.habit.id,
          _currentValue - widget.habit.currentValue,
          scaffoldContext,
        );
      }
    }
  }
}
