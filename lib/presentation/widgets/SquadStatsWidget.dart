import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hive_provider.dart';
import 'NeuralGaugePainter.dart';

class SquadStatsWidget extends StatelessWidget {
  const SquadStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SQUADRON_TELEMETRY",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white24,
              fontSize: 8,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: hive.members
                .map((member) => _buildMemberGauge(member))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberGauge(dynamic member) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: CustomPaint(
            painter: NeuralGaugePainter(
              progress: member.syncRate,
              color: member.syncRate > 0.8 ? Colors.cyanAccent : Colors.white24,
            ),
            child: Center(
              child: Text(
                "${(member.syncRate * 100).toInt()}%",
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          member.displayName.split('-').last, // Shortens "SENTINEL-04" to "04"
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
