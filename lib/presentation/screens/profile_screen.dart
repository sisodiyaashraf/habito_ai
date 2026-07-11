import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habito_ai/presentation/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// Providers
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/notification_provider.dart';

// Screens & Widgets
import 'neural_archive_screen.dart';
import 'neural_customizer_screen.dart';
import 'neural_backup_screen.dart';
import '../widgets/robot_guide_overlay.dart';
import '../widgets/sentinel_identity_hud.dart';
import '../../core/utils/responsive.dart';

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
            final String activePersona = aiProvider.currentPersona;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -50,
                    child: _buildGlow(
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),

                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildSliverAppBar(context),

                      // 1. IDENTITY HEADER
                      SliverToBoxAdapter(
                        child: FadeInDown(
                          child: _buildIdentityHeader(
                            context,
                            aiProvider,
                            currentLevel,
                            progress,
                            name,
                            aiProvider.userImagePath,
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
                              aiProvider,
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
    final Color color = isWarning
        ? Colors.redAccent
        : Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.8) : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
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
    pinned: true,
    centerTitle: true,
    title: Text(
      "SENTINEL DOSSIER",
      style: TextStyle(
        fontFamily: 'Orbitron',
        letterSpacing: 6,
        fontSize: Responsive.scaleText(context, 10),
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
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
          icon: Icon(
            Icons.settings_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
      ),
    ],
  );

  Widget _buildNeuralSettings(
    BuildContext context,
    NotificationProvider notify,
    AIProvider ai,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
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
          _buildDivider(),
          _buildSettingToggle(
            title: "HAPTIC FEEDBACK",
            subtitle: "SYSTEM-WIDE TACTILE PULSES",
            value: ai.isHapticEnabled,
            icon: Icons.vibration_rounded,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              ai.toggleHaptic(val);
            },
          ),
          _buildDivider(),
          _buildSettingToggle(
            title: "GLITCH EFFECTS",
            subtitle: "NEURAL VISUAL STABILITY",
            value: ai.isGlitchEnabled,
            icon: Icons.error_outline_rounded,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              ai.toggleGlitch(val);
            },
          ),
          _buildDivider(),
          _buildSettingToggle(
            title: "STEALTH MODE",
            subtitle: "UI CLOAKING FOR FOCUS",
            value: notify.isStealthModeEnabled,
            icon: Icons.security_rounded,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              notify.toggleStealthMode(val);
            },
          ),
          _buildDivider(),
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

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      height: 1,
    ),
  );

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Orbitron',
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: Responsive.scaleText(context, 11),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          fontSize: Responsive.scaleText(context, 7),
          letterSpacing: 1,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        activeThumbColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildStatsRow(HabitProvider habit) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: themeColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatHUDItem("HIGHEST_STREAK", "${habit.highestStreak}D", Icons.local_fire_department_rounded, themeColor),
              _buildStatHUDItem("SYNC_RATE", "${(habit.averageCompletionRate * 100).toInt()}%", Icons.sync_rounded, Colors.greenAccent),
              _buildStatHUDItem("TOTAL_XP", "${habit.totalXP}", Icons.bolt_rounded, Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 25),
          // System Stability Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "NEURAL_STABILITY",
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: themeColor.withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    habit.habits.isEmpty
                        ? "OPTIMAL"
                        : (habit.weekStability >= 0.7
                            ? "OPTIMAL"
                            : (habit.weekStability >= 0.3 ? "STABLE" : "UNSTABLE")),
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: habit.habits.isEmpty || habit.weekStability >= 0.7
                          ? Colors.greenAccent
                          : (habit.weekStability >= 0.3 ? Colors.amberAccent : Colors.redAccent),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: habit.habits.isEmpty ? 1.0 : habit.weekStability,
                  minHeight: 4,
                  backgroundColor: themeColor.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    habit.habits.isEmpty || habit.weekStability >= 0.7
                        ? Colors.greenAccent.withValues(alpha: 0.8)
                        : (habit.weekStability >= 0.3
                            ? Colors.amberAccent.withValues(alpha: 0.8)
                            : Colors.redAccent.withValues(alpha: 0.8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatHUDItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: color.withValues(alpha: 0.4),
            fontSize: 7,
            fontWeight: FontWeight.bold,
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
    String imagePath,
  ) {
    double hudSize = Responsive.isMobile(context) ? 220 : 260;
    final themeColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        const SizedBox(height: 30),
        
        // THE NEW CUSTOM HUD
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NeuralCustomizerScreen()),
            );
          },
          child: Hero(
            tag: 'profile_hud',
            child: SentinelIdentityHUD(
              size: hudSize,
              label: name.toUpperCase(),
              subLabel: "SENTINEL ID: ${ai.sentinelId}",
              themeColor: themeColor,
              progress: progress,
              imagePath: imagePath,
            ),
          ),
        ),

        const SizedBox(height: 35),

        // System Level Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: themeColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: themeColor, size: 14),
              const SizedBox(width: 8),
              Text(
                "SYSTEM_LVL: $level",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: themeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        
        Text(
          "ENCRYPTION: QUANTUM-ACTIVE",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
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

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: Responsive.scaleText(context, 10),
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: Responsive.scaleText(context, 7),
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          _showResetWarning(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
          ),
          child: const Center(
            child: Text(
              "INITIATE SECURITY OVERRIDE",
              style: TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Orbitron',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        title: const Text(
          "SECURITY_ALERT",
          style: TextStyle(fontFamily: 'Orbitron', color: Colors.redAccent, fontSize: 14),
        ),
        content: const Text(
          "This action will permanently purge all neural history and local data logs. Proceed with extreme caution.",
          style: TextStyle(fontFamily: 'SpaceMono', color: Colors.white70, fontSize: 10),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ABORT", style: TextStyle(fontFamily: 'SpaceMono', color: Colors.cyanAccent)),
          ),
          TextButton(
            onPressed: () {
              context.read<HabitProvider>().resetProgress();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text("EXECUTE_PURGE", style: TextStyle(fontFamily: 'SpaceMono', color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
