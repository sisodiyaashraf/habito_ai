import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

// Internal Logic Imports
import '../providers/habit_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/RewardScratchDialog.dart';
import '../../presentation/widgets/rewardcontent.dart';

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
    // Default to 25 mins if not specified (Pomodoro Standard)
    final minutes = widget.habit.timerMinutes ?? 25;
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
        debugPrint("NEURAL_UPLINK: Ghost Mode Engaged");
      } else {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
        debugPrint("NEURAL_UPLINK: Ghost Mode Disengaged");
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
          if (mounted) setState(() => _secondsRemaining--);
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

    // 1. DISENGAGE HARDWARE LOCKS
    await _handleGhostMode(false);
    HapticFeedback.vibrate();

    // 2. AUDIO FEEDBACK
    if (!notifyPrefs.isMuteEnabled) {
      try {
        // Ensure path matches your pubspec.yaml assets
        await _audioPlayer.play(AssetSource('sounds/victory_chime.mp3'));
      } catch (e) {
        debugPrint("Audio Playback Error: $e");
      }
    }

    // 3. ATOMIC REWARD PROTOCOL
    // We trigger the reward via the HabitProvider to ensure
    // it follows the central XP/Log/Reward logic.
    if (mounted) {
      // Use the toggleHabit which contains the _processCompletion logic
      await habitProvider.toggleHabit(widget.habit.id, context);
    }

    if (mounted) {
      setState(() {
        _isRunning = false;
        _secondsRemaining = _totalDurationSeconds;
      });
    }
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
