import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import '../providers/habit_provider.dart';

class NeuralArchiveScreen extends StatelessWidget {
  const NeuralArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();

    // CRITICAL UPDATE: Filter logs to show ONLY cards that have been collected (is_collected == true)
    final botArchives = habitProvider.systemLogs
        .where(
          (log) => log['reward_bot_id'] != null && log['is_collected'] == true,
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF03050B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "NEURAL ARCHIVE",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: botArchives.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68, // Optimal trading card geometry
              ),
              itemCount: botArchives.length,
              itemBuilder: (context, index) {
                final log = botArchives[index];
                // Safely parse the color from the log metadata
                final themeColor = Color(
                  log['reward_color'] ?? Colors.cyanAccent.value,
                );

                return FadeInUp(
                  delay: Duration(milliseconds: index * 50),
                  child: _buildFullBleedCard(
                    botName: log['reward_bot_id'],
                    frontPath: log['reward_image_path'],
                    backPath: log['reward_back_path'],
                    themeColor: themeColor,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFullBleedCard({
    required String botName,
    required String frontPath,
    required String backPath,
    required Color themeColor,
  }) {
    final controller = FlipCardController();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // Neon structural border
        border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // --- FULL-IMAGE FLIP CARD ---
            FlipCard(
              rotateSide: RotateSide.bottom,
              onTapFlipping: true,
              axis: FlipAxis.vertical,
              controller: controller,
              frontWidget: _buildCardImage(frontPath),
              backWidget: _buildCardImage(backPath),
            ),

            // --- HUD OVERLAY: BOT IDENTITY ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                child: Text(
                  botName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: themeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String path) {
    return SizedBox.expand(
      child: Image.asset(
        path,
        fit: BoxFit.cover, // Ensures the card surface is fully saturated
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF0D1117),
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white10,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeIn(
            duration: const Duration(seconds: 2),
            child: Icon(
              Icons.lock_outline_rounded,
              color: Colors.white.withOpacity(0.05),
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "ARCHIVE OFFLINE",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white.withOpacity(0.1),
              letterSpacing: 5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "DECRYPT DATA PACKS IN THE GAME HUB TO POPULATE",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white.withOpacity(0.05),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
