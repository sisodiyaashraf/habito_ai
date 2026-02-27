import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../core/services/personality_constants.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';

class NeuralProfileScreen extends StatelessWidget {
  const NeuralProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitProvider>();
    final hive = context.watch<HiveProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(habit, hive),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildStatGrid(habit),
                  const SizedBox(height: 30),
                  // NEW: Persona Selector
                  _buildHandlerSelector(hive),
                  const SizedBox(height: 30),
                  // UPDATED: Dynamic AI Recap
                  _buildNeuralRecap(hive, habit),
                  const SizedBox(height: 30),
                  _buildAchievementVault(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: NEURAL HANDLER SELECTOR ---
  Widget _buildHandlerSelector(HiveProvider hive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SELECT_NEURAL_HANDLER",
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white24,
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _handlerCard(
                hive,
                HandlerPersona.bestie,
                "BESTIE",
                "💅",
                Colors.pinkAccent,
              ),
              _handlerCard(
                hive,
                HandlerPersona.flirt,
                "FLIRT",
                "🌹",
                Colors.redAccent,
              ),
              _handlerCard(
                hive,
                HandlerPersona.brutal,
                "BRUTAL",
                "🖤",
                Colors.orangeAccent,
              ),
              _handlerCard(
                hive,
                HandlerPersona.system,
                "SYSTEM",
                "🤖",
                Colors.cyanAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _handlerCard(
    HiveProvider hive,
    HandlerPersona persona,
    String label,
    String emoji,
    Color color,
  ) {
    bool isSelected = hive.activePersona == persona;
    return GestureDetector(
      onTap: () => hive.setHandler(persona),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 9,
                color: isSelected ? color : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED: DYNAMIC NEURAL RECAP ---
  Widget _buildNeuralRecap(HiveProvider hive, HabitProvider habit) {
    String message = "";
    double completion = habit.averageCompletionRate;

    switch (hive.activePersona) {
      case HandlerPersona.bestie:
        message = completion > 0.7
            ? "Bestie, you're literally slaying these habits. Main character energy confirmed. 💅"
            : "Not you ghosting your goals... It's giving flop era. We need a comeback. 💀";
        break;
      case HandlerPersona.flirt:
        message = completion > 0.7
            ? "You look so good when you're being productive. Keep making me look good. 😉"
            : "I missed you in the terminal today. Don't make me wait, come sync with me. ❤️";
        break;
      case HandlerPersona.brutal:
        message = completion > 0.7
            ? "Finally. You did the bare minimum. Don't expect a medal for doing your job. 🙄"
            : "Is this a joke? Your discipline index is embarrassing. Stay average if you want. 🖤";
        break;
      case HandlerPersona.system:
        message =
            "NEURAL_ANALYSIS: Sync rate is at ${(completion * 100).toInt()}%. Protocol stability maintained.";
        break;
    }

    return FadeIn(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NEURAL_RECAP_LOG",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.cyanAccent,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "\"$message\"",
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                color: Colors.white70,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- EXISTING COMPONENTS (REFINED) ---
  Widget _buildSliverHeader(HabitProvider habit, HiveProvider hive) {
    return SliverAppBar(
      expandedHeight: 260,
      backgroundColor: Colors.transparent,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            _buildScanningOverlay(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildProfileAvatar(hive),
                const SizedBox(height: 15),
                Text(
                  hive.userName,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "RANK: ${habit.currentLevel > 10 ? 'ALPHA SENTINEL' : 'NEURAL INITIATE'}",
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(HiveProvider hive) {
    return ZoomIn(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyanAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 45,
          backgroundColor: const Color(0xFF1D1E33),
          child: Text(
            hive.userName[0],
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatGrid(HabitProvider habit) {
    return FadeInUp(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.6,
        children: [
          _statCard("TOTAL_XP", "${habit.totalXP}", Icons.bolt),
          _statCard("STREAK_MAX", "${habit.highestStreak}d", Icons.whatshot),
          _statCard(
            "SYNC_RATE",
            "${(habit.averageCompletionRate * 100).toInt()}%",
            Icons.sync,
          ),
          _statCard("GLOBAL_RANK", "#1420", Icons.public),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 14),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white24,
              fontSize: 8,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementVault() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "NEURAL_ACHIEVEMENTS",
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white24,
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _badgeIcon(Icons.code, "Binary Beast", true),
            _badgeIcon(Icons.self_improvement, "Zen Master", false),
            _badgeIcon(Icons.fitness_center, "Hardware Pro", true),
          ],
        ),
      ],
    );
  }

  Widget _badgeIcon(IconData icon, String label, bool unlocked) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? Colors.cyanAccent.withOpacity(0.1)
                  : Colors.transparent,
              border: Border.all(
                color: unlocked ? Colors.cyanAccent : Colors.white10,
              ),
            ),
            child: Icon(
              icon,
              color: unlocked ? Colors.cyanAccent : Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 8,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Opacity(
      opacity: 0.05,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/grid_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
