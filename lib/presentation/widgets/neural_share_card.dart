import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NeuralShareCard extends StatelessWidget {
  final int level;
  final String rank;
  final List<String> topBadges;

  const NeuralShareCard({
    super.key,
    required this.level,
    required this.rank,
    required this.topBadges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080, // High-res width for social sharing
      height: 1920, // 9:16 aspect ratio
      padding: const EdgeInsets.all(80),
      decoration: const BoxDecoration(
        color: Color(0xFF060912),
        image: DecorationImage(
          image: AssetImage('assets/images/terminal_bg.png'), // Grid overlay
          opacity: 0.1,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Spacer(),
          _buildMainStats(),
          const SizedBox(height: 60),
          _buildBadgeDisplay(),
          const Spacer(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SENTINEL IDENTIFICATION",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 24,
            letterSpacing: 10,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "LVL $level",
          style: TextStyle(
            color: Colors.white,
            fontSize: 120,
            fontWeight: FontWeight.bold,
            letterSpacing: 5,
          ),
        ),
        Text(
          rank.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 40,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeDisplay() {
    return Row(
      children: topBadges
          .map(
            (icon) => Padding(
              padding: const EdgeInsets.only(right: 30),
              child: Text(icon, style: const TextStyle(fontSize: 80)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "NEURAL HIVE // ENCRYPTED DATA",
          style: TextStyle(color: Colors.white12, fontSize: 20),
        ),
        Icon(Icons.qr_code_2, color: Colors.cyanAccent, size: 80),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.bolt, color: Colors.cyanAccent, size: 60),
        Text(
          DateTime.now().toString().substring(0, 10),
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 24,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}
