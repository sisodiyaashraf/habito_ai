import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/services/ai_service.dart';
import '../providers/hive_provider.dart';
import '../providers/ai_provider.dart';

class HiveChatTerminal extends StatefulWidget {
  const HiveChatTerminal({super.key});

  @override
  State<HiveChatTerminal> createState() => _HiveChatTerminalState();
}

class _HiveChatTerminalState extends State<HiveChatTerminal> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _triggerGhostwriter() async {
    final hive = context.read<HiveProvider>();
    final ai = context.read<AIProvider>();

    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      final suggestion = await AIService(ai.apiKey).generateGhostwriterMessage(
        stability: hive.hiveStability,
        persona: ai.currentPersona,
      );

      setState(() {
        _controller.text = suggestion;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    } catch (e) {
      debugPrint("Neural Link Error: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final stability = hive.hiveStability;
    final bool isCritical = stability < 0.5;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Stack(
        // Wrap content in a Stack to allow the floating robot
        clipBehavior: Clip.none,
        children: [
          // --- MAIN TERMINAL CONTAINER ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF060912).withOpacity(0.98),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isCritical
                    ? Colors.redAccent.withOpacity(0.4)
                    : Colors.cyanAccent.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCritical ? Colors.redAccent : Colors.cyanAccent)
                      .withOpacity(0.05),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTerminalHeader(stability, isCritical),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                Expanded(child: _buildMessageList(hive)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildGhostwriterPill(),
                      const SizedBox(width: 8),
                      if (!hive.isMissionActive) _buildMissionChip(hive),
                    ],
                  ),
                ),
                _buildTerminalInput(context, isCritical),
              ],
            ),
          ),

          // --- FLOATING ROBOT SIDEKICK ---
          _buildRobotSidekick(),
        ],
      ),
    );
  }

  Widget _buildRobotSidekick() {
    return Positioned(
      top: 40, // Positioned relative to the top of the terminal
      right: -59, // Slightly overlapping the right border for depth
      child: IgnorePointer(
        // Robot won't block clicks on messages behind it
        child: FadeInRight(
          duration: const Duration(milliseconds: 800),

          child: Image.asset(
            'assets/robots/robotguide1.png',
            height: 110, // Scaled for the terminal area
            fit: BoxFit.contain,
            // Adding a subtle glow effect to the robot asset
            colorBlendMode: BlendMode.screen,
            opacity: const AlwaysStoppedAnimation(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalHeader(double stability, bool isCritical) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Flash(
              infinite: true,
              duration: const Duration(seconds: 3),
              child: _buildStatusPulse(
                isCritical ? Colors.redAccent : Colors.cyanAccent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "NEURAL_UPLINK",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.white.withOpacity(0.4),
                fontSize: 8,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          "${(stability * 100).toInt()}% SYNC",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: isCritical ? Colors.redAccent : Colors.cyanAccent,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPulse(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 1)],
      ),
    );
  }

  Widget _buildMissionChip(HiveProvider hive) {
    return FadeInLeft(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          hive.dispatchMission(context, "SYNC 50 HABITS");
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_moderator, color: Colors.white24, size: 10),
              const SizedBox(width: 6),
              const Text(
                "NEW MISSION",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white38,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostwriterPill() {
    return GestureDetector(
      onTap: _isGenerating ? null : _triggerGhostwriter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isGenerating
              ? Colors.cyanAccent.withOpacity(0.2)
              : Colors.cyanAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isGenerating
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.cyanAccent,
                    size: 12,
                  ),
            const SizedBox(width: 8),
            const Text(
              "AI_GHOSTWRITER",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.cyanAccent,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(HiveProvider hive) {
    final messages = hive.messages;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: messages.length,
      padding: const EdgeInsets.only(top: 10),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final msg = messages[index];
        final bool isSystem = msg['sender'] == "SYSTEM";
        final bool isCommand = msg['sender'] == "COMMAND";

        return FadeIn(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${msg['sender']} >",
                  style: TextStyle(
                    color: isSystem
                        ? Colors.redAccent
                        : (isCommand ? Colors.orangeAccent : Colors.cyanAccent),
                    fontSize: 7,
                    fontFamily: 'SpaceMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg['text']!,
                  style: TextStyle(
                    color: isSystem
                        ? Colors.redAccent.withOpacity(0.7)
                        : Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontFamily: 'SpaceMono',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTerminalInput(BuildContext context, bool isCritical) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCritical
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: _controller,
        onSubmitted: (val) => _sendMessage(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'SpaceMono',
        ),
        decoration: InputDecoration(
          hintText: "> SYNC_MESSAGE...",
          hintStyle: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white.withOpacity(0.1),
            fontSize: 9,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.keyboard_double_arrow_right_rounded,
              color: isCritical ? Colors.redAccent : Colors.cyanAccent,
              size: 20,
            ),
            onPressed: _sendMessage,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      context.read<HiveProvider>().sendMessage(_controller.text.trim());
      _controller.clear();
      HapticFeedback.lightImpact();
      _scrollToBottom();
    }
  }
}
