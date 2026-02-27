import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// Providers
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/notification_provider.dart';

// Screens
import 'neural_archive_screen.dart';
import 'neural_customizer_screen.dart';
import 'neural_backup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<HabitProvider, AIProvider, NotificationProvider>(
      builder:
          (context, habitProvider, aiProvider, notificationProvider, child) {
            final String activePersona = aiProvider.currentPersona ?? "NEUTRAL";
            final int currentLevel = habitProvider.currentLevel;
            final double progress = habitProvider.levelProgress;
            final String name = aiProvider.userName;

            return Scaffold(
              backgroundColor: const Color(0xFF03050B), // Unified background
              body: Stack(
                children: [
                  // Subtle background glow
                  Positioned(
                    top: -100,
                    right: -50,
                    child: _buildGlow(Colors.cyanAccent.withOpacity(0.08)),
                  ),

                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildSliverAppBar(),

                      // 1. IDENTITY HEADER
                      SliverToBoxAdapter(
                        child: FadeInDown(
                          child: _buildIdentityHeader(
                            context,
                            aiProvider,
                            currentLevel,
                            progress,
                            name,
                          ),
                        ),
                      ),

                      // 2. NEURAL STATISTICS (Real-time HUD)
                      SliverToBoxAdapter(
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildStatsRow(habitProvider),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      // 3. NEURAL SETTINGS (Ghost Mode & Stealth Audio)
                      SliverToBoxAdapter(
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 150),
                          child: _buildNeuralSettings(
                            context,
                            notificationProvider,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 25)),

                      // 4. SYSTEM MODULES
                      _buildModuleList(context, activePersona),

                      // 5. SECURITY OVERRIDE (Wipe Data)
                      const SliverToBoxAdapter(child: SizedBox(height: 60)),
                      SliverToBoxAdapter(
                        child: FadeIn(
                          delay: const Duration(milliseconds: 500),
                          child: _buildResetButton(context),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildNeuralSettings(
    BuildContext context,
    NotificationProvider notify,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _buildSettingToggle(
              title: "GHOST MODE",
              subtitle: "AUTO-DND DURING ACTIVE TIMERS",
              value: notify.isGhostModeEnabled,
              icon: Icons.visibility_off_rounded,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                notify.toggleGhostMode(val);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
            ),
            _buildSettingToggle(
              title: "STEALTH AUDIO",
              subtitle: "MUTE VICTORY CHIMES",
              value: notify.isMuteEnabled,
              icon: Icons.volume_off_rounded,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                notify.toggleMute(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          color: Colors.white.withOpacity(0.4),
          fontSize: 7,
          letterSpacing: 0.5,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.cyanAccent,
        activeTrackColor: Colors.cyanAccent.withOpacity(0.2),
      ),
    );
  }

  Widget _buildModuleList(BuildContext context, String persona) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildActionTile(
          context,
          title: "NEURAL CUSTOMIZER",
          subtitle: "ACTIVE: ${persona.toUpperCase()} MODE",
          icon: Icons.psychology_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NeuralCustomizerScreen(),
            ),
          ),
        ),
        _buildActionTile(
          context,
          title: "MISSION ARCHIVE",
          subtitle: "VIEW EARNED BADGES AND LEGACY LOGS",
          icon: Icons.shield_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NeuralArchiveScreen(),
            ),
          ),
        ),
        _buildActionTile(
          context,
          title: "SECURE BACKUP",
          subtitle: "UPLINK DATA TO LEGACY VAULT",
          icon: Icons.cloud_upload_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NeuralBackupScreen()),
          ),
        ),
      ]),
    );
  }

  Widget _buildIdentityHeader(
    BuildContext context,
    AIProvider ai,
    int level,
    double progress,
    String name,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.cyanAccent,
                ),
              ),
            ),
            CircleAvatar(
              radius: 68,
              backgroundColor: Colors.white.withOpacity(0.05),
              child: Icon(
                Icons.face_unlock_rounded,
                color: Colors.cyanAccent.withOpacity(0.8),
                size: 55,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "LVL $level SENTINEL",
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.cyanAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.heavyImpact();
            ai.randomizeIdentity();
          },
          icon: const Icon(
            Icons.cached_rounded,
            size: 14,
            color: Colors.white38,
          ),
          label: const Text(
            "GENERATE NEW IDENTITY",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(HabitProvider habit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("STREAK", "${habit.highestStreak}D"),
          _buildStatItem(
            "SYNC RATE",
            "${(habit.averageCompletionRate * 100).toInt()}%",
          ),
          _buildStatItem("TOTAL XP", "${habit.totalXP}"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white.withOpacity(0.3),
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 22),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white12,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Column(
      children: [
        const Text(
          "SECURITY OVERRIDE",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.redAccent,
            fontSize: 8,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onLongPress: () {
            HapticFeedback.vibrate();
            _showResetConfirmation(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.4),
                width: 1.5,
              ),
              color: Colors.redAccent.withOpacity(0.05),
            ),
            child: const Text(
              "INITIATE NEURAL RESET",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "LONG PRESS TO START WIPE SEQUENCE",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white.withOpacity(0.2),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF03050B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
          ),
          title: const Text(
            "CRITICAL OVERRIDE",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.redAccent,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            "THIS WILL PERMANENTLY WIPE ALL LOCAL PROTOCOLS, XP, AND NEURAL HISTORY. CONTINUE?",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white70,
              fontSize: 10,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCEL",
                style: TextStyle(fontFamily: 'Orbitron', color: Colors.white38),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                // Add Wipe Logic Here
                Navigator.pop(context);
              },
              child: const Text(
                "WIPE DATA",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() => const SliverAppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    title: Text(
      "SENTINEL DOSSIER",
      style: TextStyle(
        fontFamily: 'Orbitron',
        letterSpacing: 6,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.white38,
      ),
    ),
  );

  Widget _buildGlow(Color color) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
    ),
  );
}
