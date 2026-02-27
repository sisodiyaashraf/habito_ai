import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart'; // Added for Bot Flip
import 'package:habito_ai/presentation/widgets/rewardcontent.dart';
import 'package:scratcher/scratcher.dart';

class DynamicScratchCard extends StatefulWidget {
  const DynamicScratchCard({super.key});

  @override
  State<DynamicScratchCard> createState() => _DynamicScratchCardState();
}

class _DynamicScratchCardState extends State<DynamicScratchCard> {
  late RewardContent reward;
  bool _isScratched = false;
  final FlipCardController _flipController = FlipCardController();

  @override
  void initState() {
    super.initState();
    reward = RewardGenerator.getRandom();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ZoomIn(
        duration: const Duration(milliseconds: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Text: High Visibility
            Text(
              _isScratched ? "BOT UPLINK ACTIVE" : "DECRYPTING DATA...",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: _isScratched ? reward.themeColor : Colors.white54,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: reward.themeColor.withOpacity(
                      _isScratched ? 0.3 : 0.1,
                    ),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Scratcher(
                  brushSize: 60,
                  threshold: 40,
                  color: const Color(0xFF1D1E33), // Data noise color
                  // Add a texture image to the scratch layer if available
                  onThreshold: () {
                    setState(() => _isScratched = true);
                    HapticFeedback.heavyImpact();
                  },
                  child: Container(
                    height: 420,
                    width: 320,
                    color: const Color(0xFF060912),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The Flip Card: Only interactable after scratching
                        AbsorbPointer(
                          absorbing: !_isScratched,
                          child: FlipCard(
                            rotateSide: RotateSide.bottom,
                            onTapFlipping: true,
                            axis: FlipAxis.vertical,
                            controller: _flipController,
                            frontWidget: _buildCardFace(reward.frontImagePath),
                            backWidget: _buildCardFace(reward.backImagePath),
                          ),
                        ),

                        // Instructional Text
                        if (!_isScratched)
                          IgnorePointer(
                            child: Pulse(
                              child: Text(
                                "SCRATCH TO REVEAL",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.2),
                                  fontFamily: 'SpaceMono',
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Interaction Footer
            if (_isScratched)
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Text(
                      "+${reward.points} XP",
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: reward.themeColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: reward.themeColor, blurRadius: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: reward.themeColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "TRANSFER TO VAULT",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "TAP CARD TO VIEW DIRECTIVE",
                      style: TextStyle(
                        color: Colors.white24,
                        fontFamily: 'SpaceMono',
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFace(String path) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Center(child: Icon(reward.icon, color: Colors.white10, size: 50)),
        ),
      ),
    );
  }
}
