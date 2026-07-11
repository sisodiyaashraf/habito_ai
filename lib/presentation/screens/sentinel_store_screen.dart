import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class SentinelTheme {
  final String name;
  final String description;
  final Color primaryColor;
  final int xpRequired;
  final String assetPath;

  SentinelTheme({
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.xpRequired,
    required this.assetPath,
  });
}

class SentinelStoreScreen extends StatelessWidget {
  const SentinelStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitProvider>();

    final List<SentinelTheme> availableThemes = [
      SentinelTheme(
        name: "NEON_PULSE",
        description: "Standard issue sentinel cyan. High visibility.",
        primaryColor: Colors.cyanAccent,
        xpRequired: 0,
        assetPath: "assets/previews/cyan.png",
      ),
      SentinelTheme(
        name: "BLOOD_MOON",
        description: "Crisis response crimson. Increases focus.",
        primaryColor: Colors.redAccent,
        xpRequired: 1500,
        assetPath: "assets/previews/red.png",
      ),
      SentinelTheme(
        name: "AMETHYST_VOID",
        description: "Deep purple spectrum for stealth operations.",
        primaryColor: Colors.purpleAccent,
        xpRequired: 3000,
        assetPath: "assets/previews/purple.png",
      ),
      SentinelTheme(
        name: "GOLDEN_LEGACY",
        description: "The ultimate status symbol for high-rank sentinels.",
        primaryColor: const Color(0xFFFFD700),
        xpRequired: 7000,
        assetPath: "assets/previews/gold.png",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "SENTINEL_BLACK_MARKET",
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildUserBalance(habit),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: availableThemes.length,
              itemBuilder: (context, index) {
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: _buildThemeCard(
                    context,
                    availableThemes[index],
                    habit,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBalance(HabitProvider habit) {
    return Container(
      padding: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "AVAILABLE_DATA_FRAGMENTS",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white24,
              fontSize: 8,
            ),
          ),
          Text(
            "${habit.totalXP} XP",
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.cyanAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    SentinelTheme theme,
    HabitProvider habit,
  ) {
    bool isLocked = habit.totalXP < theme.xpRequired;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? Colors.white10
              : theme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          theme.name,
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: isLocked ? Colors.white24 : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            theme.description,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white38,
              fontSize: 9,
            ),
          ),
        ),
        trailing: isLocked
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white10),
                  Text(
                    "${theme.xpRequired} XP",
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white10,
                      fontSize: 8,
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () => {}, // Logic to apply theme
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  "APPLY",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
      ),
    );
  }
}
