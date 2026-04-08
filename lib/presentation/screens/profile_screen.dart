import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habito_ai/presentation/screens/settingsScreen.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// Providers
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/notification_provider.dart';

// Screens & Widgets
import 'neural_archive_screen.dart';
import 'neural_customizer_screen.dart';
import 'neural_backup_screen.dart'; // Ensure this screen exists
import '../widgets/RobotGuideOverlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- GUIDE STATE ENGINE ---
  bool _isGuideVisible = false;
  int _guideStepIndex = 0;

  final List<Map<String, String>> _profileSequence = [
    {
      'label': 'SENTINEL_DOSSIER',
      'message':
          'This is your encrypted Dossier. Here you can monitor your neural evolution and system-wide configurations.',
    },
    {
      'label': 'IDENTITY_CORE',
      'message':
          'Your Level and XP progress are tracked here. Use the Generate button if you need to mask your neural signature with a new ID.',
    },
    {
      'label': 'NEURAL_SETTINGS',
      'message':
          'Toggle Ghost Mode for stealth operation during active timers, or use Stealth Audio to silence non-critical system chimes.',
    },
    {
      'label': 'SYSTEM_MODULES',
      'message':
          'Access the Archive for legacy logs, customize your AI persona, or uplink data to the Secure Backup vault.',
    },
    {
      'label': 'SECURITY_OVERRIDE',
      'message':
          'WARNING: The Reset sequence will permanently wipe all local neural history. Only initiate in case of total system compromise.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileGuide());
  }

  Future<void> _checkProfileGuide() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    bool shouldShow = await habitProvider.shouldShowGuide('profile');
    if (shouldShow && mounted) {
      setState(() {
        _isGuideVisible = true;
        _guideStepIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<HabitProvider, AIProvider, NotificationProvider>(
      builder:
          (context, habitProvider, aiProvider, notificationProvider, child) {
            final int currentLevel = habitProvider.currentLevel;
            final double progress = habitProvider.levelProgress;
            final String name = aiProvider.userName;
            final String activePersona = aiProvider.currentPersona ?? "NEUTRAL";

            return Scaffold(
              backgroundColor: const Color(0xFF03050B),
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -50,
                    child: _buildGlow(Colors.cyanAccent.withOpacity(0.08)),
                  ),

                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildSliverAppBar(context),

                      // 1. IDENTITY HEADER (Highlight Step 1)
                      SliverToBoxAdapter(
                        child: _buildFeatureHighlight(
                          isActive: _isGuideVisible && _guideStepIndex == 1,
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
                      ),

                      // 2. NEURAL STATISTICS
                      SliverToBoxAdapter(
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildStatsRow(habitProvider),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      // 3. NEURAL SETTINGS (Highlight Step 2)
                      SliverToBoxAdapter(
                        child: _buildFeatureHighlight(
                          isActive: _isGuideVisible && _guideStepIndex == 2,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            child: _buildNeuralSettings(
                              context,
                              notificationProvider,
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 25)),

                      // 4. SYSTEM MODULES (Highlight Step 3)
                      SliverToBoxAdapter(
                        child: _buildFeatureHighlight(
                          isActive: _isGuideVisible && _guideStepIndex == 3,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildModuleList(
                            context,
                            persona: activePersona,
                          ),
                        ),
                      ),

                      // 5. SECURITY OVERRIDE (Highlight Step 4)
                      const SliverToBoxAdapter(child: SizedBox(height: 60)),
                      SliverToBoxAdapter(
                        child: _buildFeatureHighlight(
                          isActive: _isGuideVisible && _guideStepIndex == 4,
                          isWarning: true,
                          child: FadeIn(
                            delay: const Duration(milliseconds: 500),
                            child: _buildResetButton(context),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),

                  if (_isGuideVisible)
                    RobotGuideOverlay(
                      label: _profileSequence[_guideStepIndex]['label']!,
                      message: _profileSequence[_guideStepIndex]['message']!,
                      onDismiss: () {
                        setState(() {
                          if (_guideStepIndex < _profileSequence.length - 1) {
                            _guideStepIndex++;
                            HapticFeedback.lightImpact();
                          } else {
                            _isGuideVisible = false;
                            context.read<HabitProvider>().markGuideAsSeen(
                              'profile',
                            );
                            HapticFeedback.mediumImpact();
                          }
                        });
                      },
                    ),
                ],
              ),
            );
          },
    );
  }

  // --- HIGHLIGHT SYSTEM ---
  Widget _buildFeatureHighlight({
    required Widget child,
    required bool isActive,
    bool isWarning = false,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final Color color = isWarning ? Colors.redAccent : Colors.cyanAccent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? color.withOpacity(0.8) : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildSliverAppBar(BuildContext context) => SliverAppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    pinned: true, // Keeps title visible while scrolling
    centerTitle: true,
    title: const Text(
      "SENTINEL DOSSIER",
      style: TextStyle(
        fontFamily: 'Orbitron',
        letterSpacing: 6,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.white38,
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 15),
        child: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: const Icon(
            Icons.settings_outlined,
            color: Colors.cyanAccent,
            size: 22,
          ),
        ),
      ),
    ],
  );

  Widget _buildNeuralSettings(
    BuildContext context,
    NotificationProvider notify,
  ) {
    return Container(
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
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.cyanAccent,
      ),
    );
  }

  Widget _buildModuleList(BuildContext context, {required String persona}) {
    return Column(
      children: [
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
          subtitle: "VIEW EARNED BADGES",
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
          subtitle: "UPLINK TO VAULT",
          icon: Icons.cloud_upload_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NeuralBackupScreen()),
          ),
        ),
      ],
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
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white.withOpacity(0.3),
            fontSize: 8,
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
                      ),
                    ),
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
              ),
            ),
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

  Widget _buildGlow(Color color) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
    ),
  );
}
