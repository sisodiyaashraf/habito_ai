import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/hive_provider.dart';
import '../widgets/SquadStatsWidget.dart';
import '../widgets/sentient_core.dart';
import '../widgets/hive_chat_terminal.dart';

class HiveScreen extends StatelessWidget {
  const HiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final bool isCritical = hive.hiveStability < 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFF03050B),
      // Crucial: This ensures the keyboard doesn't break the UI layout
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Atmospheric Glow
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlow(
              isCritical
                  ? Colors.redAccent.withOpacity(0.12)
                  : Colors.cyanAccent.withOpacity(0.08),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. FIXED HEADER
                _buildHeader(context, hive),

                // 2. SCROLLABLE TELEMETRY HUD
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- MISSION LOGIC ---
                        if (hive.isMissionActive)
                          FadeInDown(child: _buildMissionProgress(hive))
                        else
                          FadeInDown(
                            child: _buildMissionDispatcher(context, hive),
                          ),

                        // --- SQUADRON RADAR HUD ---
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: FadeInDown(
                            delay: const Duration(milliseconds: 100),
                            child: const SquadStatsWidget(),
                          ),
                        ),

                        // --- SYSTEM STABILITY HUD ---
                        FadeInDown(
                          delay: const Duration(milliseconds: 150),
                          child: _buildStabilityCard(hive),
                        ),

                        // --- SECTION LABEL: SQUAD ---
                        _buildSectionLabel("ACTIVE SQUADRON", isCritical),

                        // --- SQUAD MEMBER NODES ---
                        FadeInUp(child: _buildMemberGrid(hive)),

                        const SizedBox(height: 25),

                        // --- SECTION LABEL: TERMINAL ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildSectionLabelTerminal(),
                        ),
                        SizedBox(height: 10),
                        // --- ENCRYPTED CHAT TERMINAL ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Container(
                            height:
                                400, // Constrained height safe inside ScrollView
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                              color: Colors.black26,
                            ),
                            child: const ClipRRect(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                              child: HiveChatTerminal(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildHeader(BuildContext context, HiveProvider hive) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    hive.copyProtocolToClipboard();
                    HapticFeedback.lightImpact();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "UPLINK: ${hive.currentHiveId ?? 'DISCONNECTED'}",
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          color: Colors.cyanAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.copy_rounded,
                        color: Colors.cyanAccent,
                        size: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "HIVE: ${hive.hiveName}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                    fontSize: 20, // Slightly smaller for better fit
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SentientCore(),
        ],
      ),
    );
  }

  Widget _buildMemberGrid(HiveProvider hive) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: hive.members.length,
      itemBuilder: (context, index) {
        final member = hive.members[index];
        return Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.05),
              child: Text(
                member.displayName[0],
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member.displayName.split(' ')[0],
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 7,
                fontFamily: 'SpaceMono',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(String title, bool isCritical) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          Icon(
            Icons.sensors,
            color: isCritical ? Colors.redAccent : Colors.cyanAccent,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabelTerminal() {
    return const Text(
      "LIVE ENCRYPTED UPLINK",
      style: TextStyle(
        fontFamily: 'Orbitron',
        color: Colors.white24,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)],
      ),
    );
  }

  Widget _buildMissionDispatcher(BuildContext context, HiveProvider hive) {
    return GestureDetector(
      onTap: () => hive.dispatchMission(context, "SYNC 50 PROTOCOLS"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: const Center(
          child: Text(
            "INITIALIZE SQUAD MISSION",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.cyanAccent,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionProgress(HiveProvider hive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MISSION: ${hive.activeMissionGoal}",
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white70,
                  fontSize: 8,
                ),
              ),
              Text(
                "${(hive.collectiveMissionProgress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: hive.collectiveMissionProgress,
            backgroundColor: Colors.white10,
            color: Colors.cyanAccent,
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityCard(HiveProvider hive) {
    final bool isCritical = hive.hiveStability < 0.5;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCritical
            ? Colors.redAccent.withOpacity(0.05)
            : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            hive.systemStatus,
            style: TextStyle(
              color: isCritical ? Colors.redAccent : Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceMono',
            ),
          ),
          Text(
            "${(hive.hiveStability * 100).toInt()}% SYNC",
            style: TextStyle(
              color: isCritical ? Colors.redAccent : Colors.cyanAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }
}
