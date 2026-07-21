import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'rewardcontent.dart';
import 'neural_card.dart';
import 'sparkle_particles.dart';

class RewardAnimationWidget extends StatefulWidget {
  final RewardContent reward;
  final VoidCallback onDismiss;

  const RewardAnimationWidget({
    super.key,
    required this.reward,
    required this.onDismiss,
  });

  static void show(BuildContext context, RewardContent reward) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Reward",
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (context, anim1, anim2) {
        return RewardAnimationWidget(
          reward: reward,
          onDismiss: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  State<RewardAnimationWidget> createState() => _RewardAnimationWidgetState();
}

class _RewardAnimationWidgetState extends State<RewardAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  bool _isRevealed = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _isRevealed = true);
          HapticFeedback.heavyImpact();
          // Delay showing details until flip animation completes roughly
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) setState(() => _showDetails = true);
          });
        }
      });
    _scanController.forward();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.reward.themeColor;

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          if (_isRevealed)
            FadeIn(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.15),
                          blurRadius: 150,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: SparkleParticles(color: themeColor),
                  ),
                ],
              ),
            ),

          // The Card Container
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRevealed ? "UPLINK_SUCCESS" : "DECRYPTING_NEURAL_DATA...",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 30),
              
              // 3D Card
              Stack(
                alignment: Alignment.center,
                children: [
                  NeuralCard(
                    frontImage: widget.reward.frontImagePath,
                    backImage: widget.reward.backImagePath,
                    themeColor: themeColor,
                    isRevealed: _isRevealed,
                  ),

                  // Scanning Line
                  if (!_isRevealed)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Positioned(
                          top: 400 * _scanController.value,
                          child: Container(
                            width: 280,
                            height: 3,
                            decoration: BoxDecoration(
                              color: themeColor,
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor,
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  
                  // Glitch Effect during scan
                  if (!_isRevealed)
                    _buildGlitchOverlay(themeColor),
                ],
              ),

              const SizedBox(height: 40),

              if (_showDetails)
                FadeInUp(
                  child: Column(
                    children: [
                      Text(
                        widget.reward.botName,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(color: themeColor.withValues(alpha: 0.5), blurRadius: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.reward.icon, color: themeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "+${widget.reward.points} NEURAL XP",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              color: themeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                        child: const Text(
                          "COLLECT UNIT",
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlitchOverlay(Color color) {
    return Positioned.fill(
      child: StreamBuilder<int>(
        stream: Stream.periodic(const Duration(milliseconds: 100), (i) => i),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data! % 5 == 0) {
            return Container(
              color: color.withValues(alpha: 0.1),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
