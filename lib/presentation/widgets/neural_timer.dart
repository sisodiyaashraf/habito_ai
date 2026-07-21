import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';

class NeuralTimer extends StatefulWidget {
  final String habitName;
  final bool isReverse;
  final int targetMinutes;
  final VoidCallback? onComplete;

  const NeuralTimer({
    super.key,
    required this.habitName,
    this.isReverse = true,
    this.targetMinutes = 25,
    this.onComplete,
  });

  @override
  State<NeuralTimer> createState() => _NeuralTimerState();
}

class _NeuralTimerState extends State<NeuralTimer>
    with TickerProviderStateMixin {
  late int _secondsRemaining;
  late int _totalSeconds;
  bool _isActive = false;
  bool _isPaused = false;
  Timer? _timer;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.targetMinutes * 60;
    _secondsRemaining = _totalSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );

    _progressController.value = 0.0;
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();

    if (_isActive && !_isPaused) {
      _timer?.cancel();
      _waveController.stop();
      _progressController.stop();
      setState(() {
        _isPaused = true;
      });
    } else {
      setState(() {
        _isActive = true;
        _isPaused = false;
      });
      _waveController.repeat();
      _progressController.forward(from: _progressController.value);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_secondsRemaining > 0) {
              _secondsRemaining--;
              if (_secondsRemaining % 10 == 0) HapticFeedback.lightImpact();
            } else {
              _finishSession();
            }
          });
        }
      });
    }
  }

  void _finishSession() {
    _timer?.cancel();
    _waveController.stop();
    _progressController.stop();
    _isActive = false;
    _isPaused = false;
    HapticFeedback.vibrate();
    
    // Immediate callback for instant reward generation and custom animation
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _resetTimer() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    _waveController.stop();
    _progressController.stop();
    _progressController.value = 0.0;
    setState(() {
      _isActive = false;
      _isPaused = false;
      _secondsRemaining = _totalSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatTime() {
    int mins = _secondsRemaining ~/ 60;
    int secs = _secondsRemaining % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic realistic water color
    final Color waterColor = Color.lerp(
      Colors.cyanAccent.withValues(alpha: 0.5),
      theme.colorScheme.primary.withValues(alpha: 0.8),
      _progressController.value,
    )!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: _isActive && !_isPaused
            ? LinearGradient(
                colors: [Colors.cyanAccent, theme.colorScheme.primary.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(38),
          border: Border.all(
            color: _isActive
                ? Colors.cyanAccent.withValues(alpha: 0.5)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            if (_isActive && !_isPaused)
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          children: [
            _buildStatusHeader(context),
            const SizedBox(height: 40),

            ScaleTransition(
              scale: _isActive && !_isPaused
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer decorative ring
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),

                  // Circular Water Container
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.2),
                      border: Border.all(
                        color: _isActive ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white10,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _waveController,
                          _progressController,
                        ]),
                        builder: (context, child) {
                          return CustomPaint(
                            painter: WaterPainter(
                              progress: _progressController.value,
                              waveValue: _waveController.value,
                              color: waterColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Digital Overlay (Scanner line effect)
                  if (_isActive && !_isPaused)
                    _buildScannerLine(),

                  // Time Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(),
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: _isPaused
                              ? Colors.amberAccent
                              : theme.colorScheme.onSurface,
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                            if (_isActive && !_isPaused)
                              const Shadow(
                                color: Colors.cyanAccent,
                                blurRadius: 15,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPaused ? "SYNC_INTERRUPTED" : "DATA_STREAM_v.4",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: _isPaused ? Colors.amberAccent.withValues(alpha: 0.5) : Colors.cyanAccent.withValues(alpha: 0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
            _buildControls(context),
            if (_isActive) _buildResetButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerLine() {
    return Positioned.fill(
      child: FadeIn(
        child: TweenAnimationBuilder(
          duration: const Duration(seconds: 4),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.linear,
          onEnd: () {},
          builder: (context, double val, child) {
            return Stack(
              children: [
                Positioned(
                  top: 250 * ((math.sin(DateTime.now().millisecondsSinceEpoch / 1000) + 1) / 2),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildBlinkingDot(),
                const SizedBox(width: 8),
                Text(
                  _isActive
                      ? (_isPaused ? "LINK_PAUSED" : "LINK_ACTIVE")
                      : "STANDBY_MODE",
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.cyanAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.habitName.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        _buildHolographicGauge(context),
      ],
    );
  }

  Widget _buildBlinkingDot() {
    if (!_isActive || _isPaused) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.cyanAccent.withValues(alpha: 0.3),
        ),
      );
    }

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, double val, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyanAccent.withValues(alpha: val),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: val),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHolographicGauge(BuildContext context) {
    final theme = Theme.of(context);
    double progress = 1.0 - (_secondsRemaining / _totalSeconds);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 65,
          height: 65,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
        Text(
          "${(progress * 100).toInt()}%",
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.cyanAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _toggleTimer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: _isPaused
              ? Colors.amberAccent.withValues(alpha: 0.1)
              : (_isActive
                    ? Colors.cyanAccent.withValues(alpha: 0.15)
                    : Colors.cyanAccent.withValues(alpha: 0.2)),
          border: Border.all(
            color: _isPaused ? Colors.amberAccent : Colors.cyanAccent,
            width: 2,
          ),
          boxShadow: [
            if (_isActive && !_isPaused)
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                blurRadius: 25,
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isActive && !_isPaused
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: _isPaused
                  ? Colors.amberAccent
                  : (_isActive
                        ? Colors.cyanAccent
                        : theme.colorScheme.onSurface),
              size: 32,
            ),
            const SizedBox(width: 15),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isActive && !_isPaused
                      ? "PAUSE_UPLINK"
                      : (_isPaused ? "RESUME_UPLINK" : "START_SYNCHRONIZATION"),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: _isPaused
                        ? Colors.amberAccent
                        : (_isActive
                              ? Colors.cyanAccent
                              : theme.colorScheme.onSurface),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: TextButton(
        onPressed: _resetTimer,
        child: Text(
          "TERMINATE_PROTOCOL",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: theme.brightness == Brightness.dark
                ? Colors.redAccent.withValues(alpha: 0.6)
                : Colors.red,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class WaterPainter extends CustomPainter {
  final double progress;
  final double waveValue;
  final Color color;

  WaterPainter({
    required this.progress,
    required this.waveValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Realistic Gradient Paint
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.7), color],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // progress 0.0 = FULL (y=0)
    // progress 1.0 = EMPTY (y=height)
    final double yOffset = size.height * progress;

    const double waveHeight = 12.0;
    final double waveWidth = size.width;

    // First Wave
    final path = Path();
    path.moveTo(0, yOffset);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        yOffset +
            math.sin(
                  (i / waveWidth * 2 * math.pi) + (waveValue * 2 * math.pi),
                ) *
                waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Depth layer (Realistic Reflection)
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, yOffset);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        yOffset +
            math.cos(
                  (i / waveWidth * 2 * math.pi) + (waveValue * 2 * math.pi),
                ) *
                (waveHeight * 0.5),
      );
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveValue != waveValue;
  }
}
