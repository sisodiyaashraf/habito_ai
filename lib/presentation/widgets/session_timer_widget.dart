import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:animate_do/animate_do.dart';

// Internal Logic Imports
import '../providers/habit_provider.dart';
import '../providers/notification_provider.dart';
import 'water_wave_painter.dart';

class SessionTimerWidget extends StatefulWidget {
  final dynamic habit;

  const SessionTimerWidget({super.key, required this.habit});

  @override
  State<SessionTimerWidget> createState() => _SessionTimerWidgetState();
}

class _SessionTimerWidgetState extends State<SessionTimerWidget> with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalDurationSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _dndPlugin = DoNotDisturbPlugin();
  
  late AnimationController _glowController;
  late AnimationController _waveController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    final minutes = widget.habit.timerMinutes ?? 25;
    _totalDurationSeconds = (minutes * 60).toInt();
    _secondsRemaining = _totalDurationSeconds;
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalDurationSeconds),
    );
    _progressController.value = 0.0;
  }

  Future<void> _handleGhostMode(bool enable) async {
    final notifyPrefs = context.read<NotificationProvider>();
    if (!notifyPrefs.isGhostModeEnabled) return;

    try {
      if (enable) {
        final currentFilter = await _dndPlugin.getDNDStatus();
        if (currentFilter != InterruptionFilter.none) {
          await _dndPlugin.setInterruptionFilter(InterruptionFilter.none);
          HapticFeedback.heavyImpact();
        }
      } else {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      }
    } catch (e) {
      debugPrint("Ghost Mode Error: $e");
    }
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();

    if (_isRunning && !_isPaused) {
      // Pause
      _timer?.cancel();
      _progressController.stop();
      _handleGhostMode(false);
      setState(() => _isPaused = true);
    } else {
      // Start or Resume
      _handleGhostMode(true);
      _progressController.forward(from: _progressController.value);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          if (mounted) {
            setState(() {
              _secondsRemaining--;
            });
          }
        } else {
          _completeSession();
        }
      });
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });
    }
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _progressController.stop();
    final habitProvider = context.read<HabitProvider>();
    final notifyPrefs = context.read<NotificationProvider>();
    final String habitId = widget.habit.id;

    await _handleGhostMode(false);
    HapticFeedback.vibrate();

    if (!notifyPrefs.isMuteEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/scratchonix-victory-chime-366449.mp3'));
      } catch (e) {
        debugPrint("Audio Playback Error: $e");
      }
    }

    if (mounted) {
      // Trigger reward logic
      await habitProvider.toggleHabit(habitId, context);
      
      setState(() {
        _isRunning = false;
        _isPaused = false;
        _secondsRemaining = _totalDurationSeconds;
        _progressController.value = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _glowController.dispose();
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _progressController]),
      builder: (context, child) {
        double progress = _progressController.value;
        Color themeColor = _isRunning 
            ? (_isPaused ? Colors.amberAccent : theme.colorScheme.primary) 
            : theme.colorScheme.onSurface.withOpacity(0.3);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: _isRunning && !_isPaused
                ? LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: _isRunning && !_isPaused
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.15 * _glowController.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(
                color: _isRunning ? themeColor.withOpacity(0.4) : theme.colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAnimatedGauge(context, progress, themeColor),
                    const SizedBox(width: 20),
                    _buildTimerInfo(context, themeColor),
                    _buildActionControl(context, themeColor),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickChip("+5 MIN", () => _addMinutes(5), themeColor),
                    _buildQuickChip("+10 MIN", () => _addMinutes(10), themeColor),
                    if (_isRunning)
                      _buildQuickChip("RESET", _resetTimer, Colors.redAccent),
                  ],
                ),
                if (_isRunning) 
                  FadeIn(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPulsingDot(themeColor),
                          const SizedBox(width: 8),
                          Text(
                            _isPaused ? "SESSION_PAUSED // UPLINK_STANDBY" : "FOCUS_ACTIVE // CORE_SILENCED",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              color: themeColor.withValues(alpha: 0.6),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedGauge(BuildContext context, double progress, Color color) {
    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Water Animation
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WaterWavePainter(
                    progress: progress,
                    animationValue: _waveController.value,
                    color: color.withOpacity(0.3),
                  ),
                  size: const Size(70, 70),
                );
              },
            ),
            // Progress Ring
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Icon(
              widget.habit.category == "SLEEP" ? Icons.bedtime_rounded : Icons.bolt_rounded,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerInfo(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(_secondsRemaining),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 2,
              shadows: [
                if (_isRunning && !_isPaused) Shadow(color: color, blurRadius: 10)
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.habit.name.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: color.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControl(BuildContext context, Color themeColor) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _toggleTimer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRunning && !_isPaused 
              ? theme.colorScheme.primary.withOpacity(0.1) 
              : themeColor.withOpacity(0.1),
          border: Border.all(color: themeColor, width: 2),
        ),
        child: Icon(
          _isRunning && !_isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: themeColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildPulsingDot(Color color) {
    if (_isPaused) return Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.4)));
    
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, double val, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: val),
            boxShadow: [BoxShadow(color: color.withValues(alpha: val), blurRadius: 4)],
          ),
        );
      },
    );
  }

  void _addMinutes(int mins) {
    HapticFeedback.lightImpact();
    setState(() {
      _secondsRemaining += mins * 60;
      _totalDurationSeconds += mins * 60;
    });
  }

  void _resetTimer() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    _progressController.stop();
    _progressController.value = 0.0;
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _secondsRemaining = _totalDurationSeconds;
    });
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
