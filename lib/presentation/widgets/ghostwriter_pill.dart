import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/ai_service.dart';
import '../providers/hive_provider.dart';
import '../providers/ai_provider.dart';

class GhostwriterPill extends StatefulWidget {
  const GhostwriterPill({super.key});

  @override
  State<GhostwriterPill> createState() => _GhostwriterPillState();
}

class _GhostwriterPillState extends State<GhostwriterPill> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<HiveProvider, AIProvider>(
      builder: (context, hive, ai, _) {
        final Color themeColor = _isGenerating
            ? Colors.white24
            : Colors.cyanAccent;

        return GestureDetector(
          onTap: _isGenerating
              ? null
              : () => _handleGhostwrite(context, hive, ai),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isGenerating
                  ? Colors.white.withOpacity(0.03)
                  : themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _isGenerating
                    ? Colors.white10
                    : themeColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                if (!_isGenerating)
                  BoxShadow(
                    color: themeColor.withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isGenerating
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white24,
                          ),
                        ),
                      )
                    : Icon(Icons.auto_awesome, color: themeColor, size: 14),
                const SizedBox(width: 10),
                Text(
                  _isGenerating ? "ANALYZING HIVE..." : "AI GHOSTWRITER",
                  style: TextStyle(
                    fontFamily: _isGenerating ? 'SpaceMono' : 'Orbitron',
                    color: _isGenerating ? Colors.white38 : themeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGhostwrite(
    BuildContext context,
    HiveProvider hive,
    AIProvider ai,
  ) async {
    setState(() => _isGenerating = true);
    HapticFeedback.lightImpact();

    try {
      final aiService = AIService(ai.apiKey);
      final suggestion = await aiService.generateGhostwriterMessage(
        stability: hive.hiveStability,
        persona: ai.currentPersona,
      );

      // Broadcast message as if the user said it, based on current callsign
      hive.sendMessage(suggestion, sender: hive.userName);

      HapticFeedback.heavyImpact(); // Confirms transmission
    } catch (e) {
      HapticFeedback.vibrate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF03050B),
            content: Text(
              "UPLINK ERROR: AI RE-CALIBRATING",
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: Colors.redAccent.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
