import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';
import '../providers/ai_provider.dart';
import '../screens/global_leaderboard_screen.dart';
import '../widgets/RewardScratchDialog.dart';
import '../widgets/rewardcontent.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  // Toggle between pending rewards and the collected card archive
  bool _showVault = false;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final hiveProvider = context.watch<HiveProvider>();

    // LOGIC: Filter for logs that have bot rewards but have NOT been collected yet
    final pendingLogs = habitProvider.systemLogs
        .where(
          (log) => log['reward_bot_id'] != null && log['is_collected'] != true,
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      body: Stack(
        children: [
          _buildAmbientGlows(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),

                SliverToBoxAdapter(
                  child: FadeInDown(child: _buildHiveStatusCard(hiveProvider)),
                ),

                SliverToBoxAdapter(
                  child: FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: _buildLevelCard(habitProvider),
                  ),
                ),

                // --- TAB SWITCHER: NEURAL SELECTOR ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 25,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton("ACTIVE_UPLINKS", !_showVault),
                          _buildTabButton("NEURAL_VAULT", _showVault),
                        ],
                      ),
                    ),
                  ),
                ),

                // Logic: Show pending items only in the ACTIVE_UPLINKS tab
                if (!_showVault && pendingLogs.isEmpty)
                  _buildEmptyState(
                    "NO PENDING UPLINKS\nSynchronize habits to generate data packs.",
                  )
                else if (_showVault)
                  // Redirecting Vault view to show that items are moved to the Archive Screen
                  _buildEmptyState(
                    "NEURAL VAULT TRANSFERRED\nAll collected cards are now stored in the Neural Archive.",
                  )
                else
                  _buildRewardGrid(pendingLogs),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _showVault = title == "NEURAL_VAULT");
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.cyanAccent.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: isActive ? Colors.cyanAccent : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardGrid(List<dynamic> logs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final log = logs[index];
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: _buildPendingItem(context, log),
          );
        }, childCount: logs.length),
      ),
    );
  }

  Widget _buildPendingItem(BuildContext context, dynamic log) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        // Reconstruct reward from log metadata
        final reward = RewardGenerator.getByName(log['reward_bot_id']);

        // Open scratch dialog with the specific timestamp to handle collection logic
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              RewardScratchDialog(reward: reward, timestamp: log['timestamp']),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Pulse(
                  infinite: true,
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.cyanAccent,
                    size: 45,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "DATA PACK",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  log['timestamp'].toString().substring(
                    11,
                    16,
                  ), // Show time of generation
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.cyanAccent,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HUD CARDS ---

  Widget _buildHiveStatusCard(HiveProvider hive) {
    final bool isCritical = hive.hiveStability < 0.5;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isCritical
            ? Colors.redAccent.withOpacity(0.05)
            : Colors.cyanAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isCritical
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.cyanAccent.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "HIVE STABILITY",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 3,
                  fontFamily: 'SpaceMono',
                ),
              ),
              Icon(
                Icons.radar,
                color: isCritical ? Colors.redAccent : Colors.cyanAccent,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hive.systemStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: hive.hiveStability,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCritical ? Colors.redAccent : Colors.cyanAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(HabitProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SYSTEM RANK",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  const Text(
                    "SENTINEL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "LVL ${provider.currentLevel}",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.levelProgress,
              minHeight: 12,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.cyanAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      pinned: true,
      title: const Text(
        "NEURAL_HUB",
        style: TextStyle(
          letterSpacing: 6,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: Colors.white,
          fontFamily: 'Orbitron',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard_rounded, color: Colors.cyanAccent),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GlobalLeaderboardScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white12,
            fontSize: 11,
            height: 1.6,
            fontFamily: 'SpaceMono',
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientGlows() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: _buildGlow(Colors.purpleAccent.withOpacity(0.05)),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _buildGlow(Colors.cyanAccent.withOpacity(0.05)),
        ),
      ],
    );
  }

  Widget _buildGlow(Color color) => Container(
    width: 400,
    height: 400,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 150, spreadRadius: 50)],
    ),
  );
}
