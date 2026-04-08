import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NeuralTimer extends StatefulWidget {
  final String habitName;
  final bool isReverse; // True for Countdown, False for Stopwatch
  final int targetMinutes;
  final VoidCallback? onComplete;

  const NeuralTimer({
    super.key,
    required this.habitName,
    this.isReverse = false,
    this.targetMinutes = 25,
    this.onComplete,
  });

  @override
  State<NeuralTimer> createState() => _NeuralTimerState();
}

class _NeuralTimerState extends State<NeuralTimer> {
  late int _seconds;
  bool _isActive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize: 0 for stopwatch, target seconds for countdown
    _seconds = widget.isReverse ? widget.targetMinutes * 60 : 0;
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    setState(() => _isActive = !_isActive);

    if (_isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (widget.isReverse) {
            if (_seconds > 0) {
              _seconds--;
            } else {
              _timer?.cancel();
              _isActive = false;
              HapticFeedback.vibrate();
              if (widget.onComplete != null) widget.onComplete!();
            }
          } else {
            _seconds++;
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    int mins = _seconds ~/ 60;
    int secs = _seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  double _getProgress() {
    if (!widget.isReverse) return 0.0;
    double total = widget.targetMinutes * 60.0;
    return (total - _seconds) / total;
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = widget.isReverse
        ? Colors.purpleAccent
        : Colors.cyanAccent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: _isActive
            ? activeColor.withOpacity(0.08)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isActive ? activeColor.withOpacity(0.5) : Colors.white10,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isReverse ? "REVERSE LINK ACTIVE" : "CHRONO_TRACKER",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: activeColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.habitName.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.isReverse) _buildCircularIndicator(activeColor),
            ],
          ),
          const SizedBox(height: 25),

          // Time Display
          Text(
            _formatTime(),
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),

          const SizedBox(height: 25),

          // Control Toggle
          GestureDetector(
            onTap: _toggleTimer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: _isActive
                    ? Colors.redAccent.withOpacity(0.1)
                    : activeColor.withOpacity(0.1),
                border: Border.all(
                  color: _isActive ? Colors.redAccent : activeColor,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isActive
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                    color: _isActive ? Colors.redAccent : activeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isActive ? "TERMINATE SESSION" : "INITIATE SYNC",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: _isActive ? Colors.redAccent : activeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIndicator(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: _getProgress(),
            strokeWidth: 3,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Icon(Icons.timer_outlined, size: 14, color: color),
      ],
    );
  }
}
