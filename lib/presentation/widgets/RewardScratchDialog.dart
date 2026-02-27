import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scratcher/scratcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import '../providers/habit_provider.dart';
import 'package:habito_ai/presentation/widgets/rewardcontent.dart';

class RewardScratchDialog extends StatefulWidget {
  final RewardContent reward;
  final bool isReadOnly;
  final DateTime timestamp; // Unique ID to link this card to the Provider's log

  const RewardScratchDialog({
    super.key,
    required this.reward,
    required this.timestamp,
    this.isReadOnly = false,
  });

  /// Static trigger to launch the decryption UI
  /// Requirement: Must pass context, reward, and the specific log timestamp
  static void show(
    BuildContext context,
    RewardContent reward,
    DateTime timestamp,
  ) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          RewardScratchDialog(reward: reward, timestamp: timestamp),
    );
  }

  @override
  State<RewardScratchDialog> createState() => _RewardScratchDialogState();
}

class _RewardScratchDialogState extends State<RewardScratchDialog> {
  // Key used to control and track scratch progress - Fixes unresponsive scratching
  final GlobalKey<ScratcherState> _scratchKey = GlobalKey<ScratcherState>();
  final FlipCardController _flipController = FlipCardController();
  bool _thresholdReached = false;
  int _lastHapticStep = 0;

  @override
  void initState() {
    super.initState();
    // Archive view displays the card fully decrypted immediately
    _thresholdReached = widget.isReadOnly;
  }

  @override
  Widget build(BuildContext context) {
    final Color rewardTheme = widget.reward.themeColor;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () {}, // Safety: Prevents accidental closure on tap
          child: ZoomIn(
            duration: const Duration(milliseconds: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(rewardTheme),
                const SizedBox(height: 25),

                // --- THE NEURAL SCRATCH AREA ---
                Container(
                  width: 300,
                  height: 420,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: rewardTheme.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rewardTheme.withOpacity(
                          _thresholdReached ? 0.3 : 0.1,
                        ),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Scratcher(
                      key: _scratchKey,
                      enabled: !widget.isReadOnly,
                      brushSize: 80, // Larger brush for better UX
                      threshold: 35, // Trigger reveal at 35% scratched
                      color: const Color(0xFF141625),
                      image: Image.asset(
                        "assets/images/scratchcar.jpeg",
                        fit: BoxFit.cover,
                      ),
                      onScratchUpdate: () {
                        // Light haptic feedback as the user "decrypts"
                        double? progress = _scratchKey.currentState?.progress;
                        if (progress != null) {
                          int currentStep = (progress * 100).toInt();
                          if (currentStep % 10 == 0 &&
                              currentStep != _lastHapticStep) {
                            HapticFeedback.lightImpact();
                            _lastHapticStep = currentStep;
                          }
                        }
                      },
                      onThreshold: () {
                        setState(() => _thresholdReached = true);
                        HapticFeedback.heavyImpact();
                      },
                      child: _buildFlipContent(rewardTheme),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                if (_thresholdReached) _buildCollectButton(rewardTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color themeColor) {
    return Column(
      children: [
        Text(
          widget.reward.botName.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: themeColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _thresholdReached
              ? "PROTOCOL DECRYPTED"
              : "INITIALIZING DATA SCRUB...",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: _thresholdReached
                ? themeColor.withOpacity(0.8)
                : Colors.white54,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFlipContent(Color themeColor) {
    return Container(
      color: const Color(0xFF060912),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // AbsorbPointer prevents card flipping until scratching is verified
          AbsorbPointer(
            absorbing: !_thresholdReached,
            child: FlipCard(
              rotateSide: RotateSide.bottom,
              onTapFlipping: true,
              axis: FlipAxis.vertical,
              controller: _flipController,
              frontWidget: _buildCardImage(widget.reward.frontImagePath),
              backWidget: _buildCardImage(widget.reward.backImagePath),
            ),
          ),
          if (!_thresholdReached)
            Positioned(
              bottom: 30,
              child: FadeIn(
                child: const Text(
                  "SCRATCH TO REVEAL",
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white24,
                    fontSize: 8,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardImage(String path) {
    return SizedBox.expand(
      child: Image.asset(
        path,
        fit: BoxFit.cover, // Full Edge-to-Edge image fill
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF0D1117),
          child: const Icon(Icons.bolt, color: Colors.white10, size: 50),
        ),
      ),
    );
  }

  Widget _buildCollectButton(Color themeColor) {
    return FadeInUp(
      child: Column(
        children: [
          Text(
            "+${widget.reward.points} XP",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: themeColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 10,
              shadowColor: themeColor.withOpacity(0.5),
            ),
            onPressed: () {
              // HANDSHAKE: Notify Provider that this specific log is collected
              context.read<HabitProvider>().collectBotCard(widget.timestamp);
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            child: const Text(
              "TRANSFER TO ARCHIVE",
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "ITEM WILL BE REMOVED FROM HUB AND STORED IN ARCHIVE",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white24,
              fontSize: 7,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
