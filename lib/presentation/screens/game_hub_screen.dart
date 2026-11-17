import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';
import '../screens/global_leaderboard_screen.dart';
import '../widgets/reward_animation_widget.dart';
import '../widgets/rewardcontent.dart';
import '../widgets/robot_guide_overlay.dart';
import '../widgets/bounty_board_widget.dart';
import '../widgets/rpg_attribute_matrix.dart';
import '../widgets/cyber_armory_sheet.dart';
import '../../domain/entities/rpg_stats.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/game_audio_service.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  bool _showVault = false;
  String _vaultFilter = 'ALL'; // 'ALL', 'RARE', 'GOLD'
  bool _isGuideVisible = false;
  int _guideStepIndex = 0;

  final List<Map<String, String>> _hubSequence = [
    {
      'label': 'NEURAL_HUB',
      'message':
          'Welcome to the Neural Hub. This is where your habit synchronization is converted into tangible system rewards.',
    },
    {
      'label': 'HIVE_STABILITY',
      'message':
          'Monitor the collective Hive Stability. High stability ensures optimal reward generation during squad missions.',
    },
    {
      'label': 'SYSTEM_RANK',
      'message':
          'This telemetry displays your Sentinel evolution. Progress the bar to unlock higher tier neural protocols.',
    },
    {
      'label': 'DATA_PACKS',
      'message':
          'Synchronized habits generate encrypted Data Packs. Decrypt them here to collect rare Bot Cards for your archive.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHubGuide());
  }

  Future<void> _checkHubGuide() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    bool shouldShow = await habitProvider.shouldShowGuide('gamehub');
    if (shouldShow && mounted) {
      setState(() {
        _isGuideVisible = true;
        _guideStepIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final hiveProvider = context.watch<HiveProvider>();
    final RPGStats stats = habitProvider.rpgStats;
    final theme = Theme.of(context);

    final pendingLogs = habitProvider.systemLogs.where((log) {
      return log['reward_bot_id'] != null && log['is_collected'] != true;
    }).toList();

    final allCollectedLogs = habitProvider.systemLogs.where((log) {
      return log['reward_bot_id'] != null && log['is_collected'] == true;
    }).toList();

    final filteredCollectedLogs = allCollectedLogs.where((log) {
      if (_vaultFilter == 'RARE') return log['is_rare'] == true;
      if (_vaultFilter == 'GOLD') return log['reward_bot_id'] == 'GOLDEN-SENTINEL';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildAmbientGlows(theme),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, theme, habitProvider),

                // SECTION 1: Operative RPG Dossier Hero Card
                SliverToBoxAdapter(
                  child: FadeInDown(
                    child: _buildOperativeHeroCard(habitProvider, stats, theme),
                  ),
                ),

                // SECTION 2: Hive Network Status Card
                SliverToBoxAdapter(
                  child: _buildHighlightWrapper(
                    theme,
                    isActive: _isGuideVisible && _guideStepIndex == 1,
                    child: FadeInDown(
                      delay: const Duration(milliseconds: 60),
                      child: _buildHiveStatusCard(hiveProvider, theme),
                    ),
                  ),
                ),

                // SECTION 3: Tactical Bounty Board (Daily Quests)
                const SliverToBoxAdapter(
                  child: BountyBoardWidget(),
                ),

                // SECTION 4: Sentinel RPG Attribute Matrix
                const SliverToBoxAdapter(
                  child: RpgAttributeMatrix(),
                ),

                // SECTION 5: Tabs Header (ACTIVE_UPLINKS vs NEURAL_VAULT)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scalePadding(context, 20),
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildTabButton(
                                "DATA PACKS (${pendingLogs.length})",
                                !_showVault,
                                theme,
                              ),
                              _buildTabButton(
                                "BOT VAULT (${allCollectedLogs.length})",
                                _showVault,
                                theme,
                              ),
                            ],
                          ),
                        ),

                        // Vault Sub-Filters
                        if (_showVault) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFilterChip("ALL", theme),
                              const SizedBox(width: 8),
                              _buildFilterChip("RARE", theme),
                              const SizedBox(width: 8),
                              _buildFilterChip("GOLD", theme),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // SECTION 6: Data Packs Grid or Vault Grid
                if (!_showVault)
                  pendingLogs.isEmpty
                      ? _buildEmptyUplinksState(habitProvider, theme)
                      : _buildRewardGrid(pendingLogs, isVault: false, theme: theme)
                else
                  filteredCollectedLogs.isEmpty
                      ? _buildEmptyState(
                          "NEURAL VAULT EMPTY FOR FILTER '$_vaultFilter'\nComplete protocols or summon packs to archive Bot Cards.",
                          theme,
                        )
                      : _buildRewardGrid(filteredCollectedLogs, isVault: true, theme: theme),

                // SECTION 7: Cyber Armory Quick Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        CyberArmorySheet.show(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyanAccent.withValues(alpha: 0.15),
                              Colors.purpleAccent.withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.shopping_bag_rounded, color: Colors.cyanAccent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "BLACK MARKET ARMORY",
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.cyanAccent,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Acquire Streak Shields, 2X XP Overdrive & Mystery Pods.",
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 9,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.cyanAccent, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          if (_isGuideVisible)
            RobotGuideOverlay(
              label: _hubSequence[_guideStepIndex]['label']!,
              message: _hubSequence[_guideStepIndex]['message']!,
              onDismiss: () {
                setState(() {
                  if (_guideStepIndex < _hubSequence.length - 1) {
                    _guideStepIndex++;
                    HapticFeedback.lightImpact();
                  } else {
                    _isGuideVisible = false;
                    context.read<HabitProvider>().markGuideAsSeen('gamehub');
                    HapticFeedback.mediumImpact();
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ThemeData theme) {
    final bool isSelected = _vaultFilter == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _vaultFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : theme.colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.cyanAccent : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildOperativeHeroCard(
    HabitProvider habit,
    RPGStats stats,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.scalePadding(context, 20),
        vertical: 10,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: stats.rankColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: stats.rankColor.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Holographic Avatar with Rank Insignia
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: stats.rankColor, width: 2),
                      gradient: RadialGradient(
                        colors: [
                          stats.rankColor.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(stats.rankBadge, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Operative Name & Rank Tier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.rankTitle,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        letterSpacing: 2,
                        color: stats.rankColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "LEVEL ${habit.currentLevel}",
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${habit.totalXP} TOTAL NEURAL XP",
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Combat Power Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "COMBAT POWER",
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 7,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${stats.combatPower}",
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Level progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: habit.levelProgress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(stats.rankColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUplinksState(HabitProvider habit, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 40),
              const SizedBox(height: 12),
              Text(
                "NO PENDING DATA PACKS",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Complete active daily protocols to synthesize encrypted packs, or summon a Mystery Data Pod from the Armory.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  CyberArmorySheet.show(context);
                },
                icon: const Icon(Icons.flash_on_rounded, size: 14),
                label: const Text(
                  "SUMMON POD // 120 BITS",
                  style: TextStyle(fontFamily: 'Orbitron', fontSize: 9, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.cyanAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isActive, ThemeData theme) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _showVault = title.startsWith("BOT VAULT"));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                fontSize: Responsive.scaleText(context, 9),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardGrid(List<dynamic> logs, {required bool isVault, required ThemeData theme}) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.scalePadding(context, 20)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isMobile(context) ? 2 : 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: _buildRewardCard(context, logs[index], isVault, theme),
          );
        }, childCount: logs.length),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, dynamic log, bool isVault, ThemeData theme) {
    final String botId = log['reward_bot_id'];
    final reward = RewardGenerator.getByName(botId);
    final bool isCollected = log['is_collected'] ?? false;
    final bool isRare = reward.isRare;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.heavyImpact();
        if (!isCollected) {
          final ts = log['timestamp'] is DateTime
              ? log['timestamp']
              : DateTime.parse(log['timestamp'].toString());
          await context.read<HabitProvider>().decryptDataPack(ts);
        } else {
          GameAudioService().playSoftChime();
          RewardAnimationWidget.show(context, reward);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: isVault
                ? (isRare
                    ? const Color(0xFFFFD700).withValues(alpha: 0.08)
                    : theme.colorScheme.surface.withValues(alpha: 0.6))
                : Colors.cyanAccent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isVault
                  ? (isRare
                      ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.15))
                  : Colors.cyanAccent.withValues(alpha: 0.4),
              width: isRare ? 1.5 : 1,
            ),
            boxShadow: isRare
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      blurRadius: 15,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isVault)
                Image.asset(
                  reward.frontImagePath,
                  height: Responsive.isMobile(context) ? 85 : 120,
                  fit: BoxFit.contain,
                )
              else
                Pulse(
                  infinite: true,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.cyanAccent,
                      size: Responsive.scaleText(context, 35),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                isVault ? reward.botName.toUpperCase() : "ENCRYPTED PACK",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: isRare ? const Color(0xFFFFD700) : theme.colorScheme.onSurface,
                  fontSize: Responsive.scaleText(context, 10),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isVault
                    ? (isRare ? "★ LEGENDARY SENTINEL" : "ARCHIVED SENTINEL")
                    : "TAP TO DECRYPT (+50 BITS)",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: isVault
                      ? (isRare
                          ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4))
                      : Colors.cyanAccent.withValues(alpha: 0.8),
                  fontSize: Responsive.scaleText(context, 7),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    HabitProvider habit,
  ) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      pinned: true,
      title: Text(
        "GAME_HUB",
        style: TextStyle(
          letterSpacing: 5,
          fontWeight: FontWeight.w900,
          fontSize: Responsive.scaleText(context, 13),
          color: theme.colorScheme.onSurface,
          fontFamily: 'Orbitron',
        ),
      ),
      actions: [
        // Live Bits Button in AppBar
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            CyberArmorySheet.show(context);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded, color: Colors.cyanAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  "${habit.neuralCredits}",
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.leaderboard_rounded, color: theme.colorScheme.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GlobalLeaderboardScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildHiveStatusCard(HiveProvider hive, ThemeData theme) {
    final bool isCritical = hive.hiveStability < 0.5;
    final color = isCritical ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.scalePadding(context, 20),
        vertical: 8,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HIVE COLLECTIVE STABILITY",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: Responsive.scaleText(context, 8),
                  letterSpacing: 2,
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.radar_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hive.systemStatus,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: Responsive.scaleText(context, 14),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              Text(
                "${(hive.hiveStability * 100).toInt()}%",
                style: TextStyle(
                  color: color,
                  fontSize: Responsive.scaleText(context, 12),
                  fontWeight: FontWeight.w900,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: hive.hiveStability,
              minHeight: 6,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            fontSize: Responsive.scaleText(context, 10),
            height: 1.6,
            fontFamily: 'SpaceMono',
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientGlows(ThemeData theme) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: _buildGlow(theme.colorScheme.secondary.withValues(alpha: 0.05)),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _buildGlow(theme.colorScheme.primary.withValues(alpha: 0.05)),
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

  Widget _buildHighlightWrapper(
    ThemeData theme, {
    required Widget child,
    required bool isActive,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.8)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
