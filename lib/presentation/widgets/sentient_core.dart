import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/ai_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/profile_screen.dart';

class SentientCore extends StatefulWidget {
  final String? customAvatarPath;

  const SentientCore({super.key, this.customAvatarPath});

  @override
  State<SentientCore> createState() => _SentientCoreState();
}

class _SentientCoreState extends State<SentientCore>
    with SingleTickerProviderStateMixin {
  late AnimationController _activationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flashAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _activationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(
            parent: _activationController,
            curve: Curves.easeInOut,
          ),
        );

    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _activationController, curve: Curves.easeInExpo),
    );
  }

  @override
  void dispose() {
    _activationController.dispose();
    super.dispose();
  }

  Future<void> _handleActivation() async {
    HapticFeedback.heavyImpact();

    // Play activation sequence
    await _activationController.forward();

    if (mounted) {
      // Custom Neural Transition to Profile
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeInOutCubic;
            var fadeTween = Tween(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: curve));
            var scaleTween = Tween(
              begin: 0.8,
              end: 1.0,
            ).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
        ),
      );

      // Reset controller for next time
      _activationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final hiveProvider = context.watch<HiveProvider>();
    final theme = Theme.of(context);

    final level = habitProvider.currentLevel;
    final progress = habitProvider.levelProgress;

    final notificationProvider = context.watch<NotificationProvider>();

    final aiProvider = context.watch<AIProvider>();
    final isOnline = aiProvider.isOnline;

    final Color coreColor = !isOnline
        ? Colors
              .grey // Offline color
        : (hiveProvider.hiveStability < 0.3
              ? Colors.redAccent
              : (hiveProvider.hiveStability < 0.6
                    ? Colors.orangeAccent
                    : theme.colorScheme.primary));

    final Color ghostColor = Colors.purpleAccent;
    final bool isGhostMode = notificationProvider.isGhostModeEnabled;

    const String defaultAvatar = 'assets/robots/robotguide2.png';
    final String avatarPath = widget.customAvatarPath ?? defaultAvatar;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleActivation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // --- 1. AMBIENT GLOW ---
                _buildAmbientGlow(
                  !isOnline ? Colors.redAccent.withOpacity(0.5) : coreColor,
                ),

                // --- 2. GLASS CIRCLE BACKGROUND ---
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPressed
                        ? coreColor.withOpacity(0.2)
                        : theme.colorScheme.onSurface.withOpacity(0.05),
                    border: Border.all(
                      color: _isPressed
                          ? coreColor
                          : theme.colorScheme.onSurface.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),

                // --- 3. PROGRESS TRACKER ---
                SizedBox(
                  width: 62,
                  height: 62,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(
                      0.05,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(coreColor),
                  ),
                ),

                // --- 4. HUD DETAILING ---
                _buildHUDRing(
                  isGhostMode
                      ? ghostColor.withOpacity(0.5)
                      : coreColor.withOpacity(0.3),
                  68,
                ),
                _buildHUDRing(
                  isGhostMode
                      ? ghostColor.withOpacity(0.2)
                      : coreColor.withOpacity(0.1),
                  74,
                ),

                // --- 5. ROBOT AVATAR ---
                Positioned(
                  bottom: -2,
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Transform.scale(
                      scale: 1.3,
                      child: Image.asset(
                        avatarPath,
                        height: 65,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.smart_toy_rounded,
                          color: coreColor,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

                // --- 6. SCANNING LINE ---
                _buildScanningLine(60, coreColor),

                // --- 7. NEURAL ACTIVATION FLASH ---
                FadeTransition(
                  opacity: _flashAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          coreColor.withOpacity(0.8),
                          coreColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- 8. LEVEL BADGE ---
                Positioned(
                  top: -5,
                  right: -10,
                  child: FadeInRight(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: coreColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: coreColor.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        "LVL $level",
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: coreColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "NEURAL LINK",
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: coreColor.withOpacity(0.5),
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientGlow(Color coreColor) {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: coreColor.withOpacity(0.1 + (0.1 * value)),
                blurRadius: 15 + (5 * value),
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHUDRing(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 0.5),
      ),
    );
  }

  Widget _buildScanningLine(double size, Color coreColor) {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 3),
      tween: Tween(begin: -1.0, end: 1.0),
      onEnd: () {},
      builder: (context, double value, child) {
        return ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Positioned(
                  top: (size / 2) + (value * (size / 2)),
                  child: Container(
                    width: size,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          coreColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
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
}
