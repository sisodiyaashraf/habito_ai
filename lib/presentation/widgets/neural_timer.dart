import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NeuralTimer extends StatefulWidget {
  final String habitName;
  const NeuralTimer({super.key, required this.habitName});

  @override
  State<NeuralTimer> createState() => _NeuralTimerState();
}

class _NeuralTimerState extends State<NeuralTimer> {
  int _seconds = 0;
  bool _isActive = false;
  Timer? _timer;

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    setState(() => _isActive = !_isActive);

    if (_isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _seconds++);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isActive
            ? Colors.cyanAccent.withOpacity(0.08)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isActive
              ? Colors.cyanAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: _isActive
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Protocol Label (SpaceMono)
          Text(
            "EXECUTION PROTOCOL: ${widget.habitName.toUpperCase()}",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white.withOpacity(0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 15),

          // Timer Digits (Orbitron)
          Text(
            "${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}",
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900, // Black weight for maximum impact
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 10),

          // Control Button
          GestureDetector(
            onTap: _toggleTimer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isActive
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.cyanAccent.withOpacity(0.1),
                border: Border.all(
                  color: _isActive
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.cyanAccent.withOpacity(0.5),
                ),
              ),
              child: Icon(
                _isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _isActive ? Colors.redAccent : Colors.cyanAccent,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
