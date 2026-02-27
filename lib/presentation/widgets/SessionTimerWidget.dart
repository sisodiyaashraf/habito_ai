import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habito_ai/presentation/widgets/rewardcontent.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

import '../providers/habit_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/RewardScratchDialog.dart';

class SessionTimerWidget extends StatefulWidget {
  final dynamic habit;

  const SessionTimerWidget({super.key, required this.habit});

  @override
  State<SessionTimerWidget> createState() => _SessionTimerWidgetState();
}

class _SessionTimerWidgetState extends State<SessionTimerWidget> {
  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalDurationSeconds = 0;
  bool _isRunning = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _dndPlugin = DoNotDisturbPlugin();

  @override
  void initState() {
    super.initState();
    // habit.timerMinutes is the target for the session
    final minutes = widget.habit.timerMinutes ?? widget.habit.dailyTarget;
    _totalDurationSeconds = (minutes * 60).toInt();
    _secondsRemaining = _totalDurationSeconds;
  }

  /// Manages "Ghost Mode" - Hardware level DND
  Future<void> _handleGhostMode(bool enable) async {
    final notifyPrefs = context.read<NotificationProvider>();
    if (!notifyPrefs.isGhostModeEnabled) return;

    try {
      if (enable) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.none);
        debugPrint("GHOST MODE: DND Protocol Active");
      } else {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
        debugPrint("GHOST MODE: DND Protocol Deactivated");
      }
    } catch (e) {
      debugPrint("Ghost Mode Error: $e");
    }
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();

    if (_isRunning) {
      _timer?.cancel();
      _handleGhostMode(false);
    } else {
      _handleGhostMode(true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _completeSession();
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    final habitProvider = context.read<HabitProvider>();
    final notifyPrefs = context.read<NotificationProvider>();

    // 1. Play Victory Sound
    if (!notifyPrefs.isMuteEnabled) {
      try {
        await _audioPlayer.play(
          AssetSource('sounds/scratchonix-victory-chime-366449.mp3'),
        );
      } catch (e) {
        debugPrint("Audio Playback Error: $e");
      }
    }

    HapticFeedback.vibrate();
    await _handleGhostMode(false);

    // 2. LOGIC: Identify Reward Tier & Generate Timestamp
    final timestamp = DateTime.now();

    // Check daily completions to see if we trigger Gold Card
    int todayCount =
        habitProvider.habits.where((h) {
          return h.completionDates.any(
            (d) =>
                d.year == timestamp.year &&
                d.month == timestamp.month &&
                d.day == timestamp.day,
          );
        }).length +
        1; // +1 for the current session

    final reward = todayCount >= 8
        ? RewardGenerator.getRandomGold()
        : RewardGenerator.getRandom();

    // 3. UPDATE SYSTEM: Add XP and Record to History
    await habitProvider.addXP(reward.points);

    // Update the habit entity as complete
    await habitProvider.toggleHabit(widget.habit.id, context);

    // 4. SHOW REWARD: Show the scratch card mapped to this specific session timestamp
    if (mounted) {
      RewardScratchDialog.show(context, reward, timestamp);
    }

    setState(() {
      _isRunning = false;
      _secondsRemaining = _totalDurationSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double progress = 1 - (_secondsRemaining / _totalDurationSeconds);
    Color themeColor = _isRunning
        ? Colors.cyanAccent
        : Colors.cyanAccent.withOpacity(0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      margin: EdgeInsets.symmetric(vertical: _isRunning ? 16 : 8),
      padding: EdgeInsets.all(_isRunning ? 24 : 18),
      decoration: BoxDecoration(
        color: _isRunning
            ? Colors.cyanAccent.withOpacity(0.06)
            : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isRunning
              ? Colors.cyanAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.1),
          width: _isRunning ? 1.5 : 1,
        ),
        boxShadow: _isRunning
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildGauge(progress, themeColor),
              const SizedBox(width: 20),
              _buildTimerInfo(themeColor),
              _buildActionControl(),
            ],
          ),
          if (_isRunning) _buildFocusStatus(),
        ],
      ),
    );
  }

  Widget _buildGauge(double progress, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: _isRunning ? 65 : 55,
          width: _isRunning ? 65 : 55,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: _isRunning ? 4 : 3,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        Icon(
          widget.habit.category == "SLEEP"
              ? Icons.bedtime_rounded
              : Icons.bolt_rounded,
          color: color,
          size: _isRunning ? 22 : 18,
        ),
      ],
    );
  }

  Widget _buildTimerInfo(Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(_secondsRemaining),
            style: TextStyle(
              color: Colors.white,
              fontSize: _isRunning ? 34 : 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isRunning ? "GHOST MODE: DND ACTIVE" : "SESSION READY",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: _isRunning
                  ? Colors.cyanAccent
                  : Colors.white.withOpacity(0.5),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControl() {
    return GestureDetector(
      onTap: _toggleTimer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRunning
              ? Colors.redAccent.withOpacity(0.15)
              : Colors.cyanAccent.withOpacity(0.15),
          border: Border.all(
            color: _isRunning
                ? Colors.redAccent.withOpacity(0.6)
                : Colors.cyanAccent.withOpacity(0.6),
          ),
        ),
        child: Icon(
          _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: _isRunning ? Colors.redAccent : Colors.cyanAccent,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildFocusStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        "CORE SILENCED // REDIRECTED TO: ${widget.habit.name.toUpperCase()}",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          color: Colors.white.withOpacity(0.4),
          fontSize: 8,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
