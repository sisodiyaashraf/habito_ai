import 'dart:ui';
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
import '../../core/utils/responsive.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  bool _showVault = false;
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
    final theme = Theme.of(context);

    final pendingLogs = habitProvider.systemLogs.where((log) {
      return log['reward_bot_id'] != null && log['is_collected'] != true;
    }).toList();

    final collectedLogs = habitProvider.systemLogs.where((log) {
      return log['reward_bot_id'] != null && log['is_collected'] == true;
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
                _buildAppBar(context, theme),

                SliverToBoxAdapter(
                  child: _buildHighlightWrapper(
                    theme,
                    isActive: _isGuideVisible && _guideStepIndex == 1,
                    child: FadeInDown(
                      child: _buildHiveStatusCard(hiveProvider, theme),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildHighlightWrapper(
                    theme,
                    isActive: _isGuideVisible && _guideStepIndex == 2,
                    child: FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      child: _buildLevelCard(habitProvider, theme),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scalePadding(context, 25),
                      vertical: 25,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton("ACTIVE_UPLINKS", !_showVault, theme),
                          _buildTabButton("NEURAL_VAULT", _showVault, theme),
                        ],
                      ),
                    ),
                  ),
                ),

                if (!_showVault)
                  pendingLogs.isEmpty
                      ? _buildEmptyState("NO PENDING UPLINKS\nComplete protocols to generate data packs.", theme)
                      : _buildRewardGrid(pendingLogs, isVault: false, theme: theme)
                else
                  collectedLogs.isEmpty
                      ? _buildEmptyState("NEURAL VAULT EMPTY\nCollected cards will be archived here.", theme)
                      : _buildRewardGrid(collectedLogs, isVault: true, theme: theme),

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

  Widget _buildTabButton(String title, bool isActive, ThemeData theme) {
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
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.24),
                fontSize: Responsive.scaleText(context, 10),
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
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.8,
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        if (!isCollected) {
          context.read<HabitProvider>().collectBotCard(log['timestamp'] is DateTime ? log['timestamp'] : DateTime.parse(log['timestamp'].toString()));
        }
        RewardAnimationWidget.show(context, reward);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: isVault
                ? theme.colorScheme.onSurface.withOpacity(0.02)
                : theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isVault
                  ? theme.colorScheme.onSurface.withOpacity(0.1)
                  : theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isVault)
                Image.asset(
                  reward.frontImagePath,
                  height: Responsive.isMobile(context) ? 80 : 120,
                  fit: BoxFit.contain,
                )
              else
                Pulse(
                  infinite: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: theme.colorScheme.primary,
                      size: Responsive.scaleText(context, 35),
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              Text(
                isVault ? reward.botName.toUpperCase() : "ENCRYPTED PACK",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: theme.colorScheme.onSurface,
                  fontSize: Responsive.scaleText(context, 10),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isVault ? "DECRYPTED_SENTINEL" : "TAP TO DECRYPT",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: isVault
                      ? theme.colorScheme.onSurface.withOpacity(0.24)
                      : theme.colorScheme.primary.withOpacity(0.5),
                  fontSize: Responsive.scaleText(context, 7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      pinned: true,
      title: Text(
        "NEURAL_HUB",
        style: TextStyle(
          letterSpacing: 6,
          fontWeight: FontWeight.w900,
          fontSize: Responsive.scaleText(context, 14),
          color: theme.colorScheme.onSurface,
          fontFamily: 'Orbitron',
        ),
      ),
      actions: [
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
      margin: EdgeInsets.symmetric(horizontal: Responsive.scalePadding(context, 20), vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HIVE STABILITY",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.38),
                  fontSize: Responsive.scaleText(context, 9),
                  letterSpacing: 3,
                  fontFamily: 'SpaceMono',
                ),
              ),
              Icon(
                Icons.radar,
                color: color,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hive.systemStatus,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: Responsive.scaleText(context, 18),
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
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(HabitProvider provider, ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.scalePadding(context, 20), vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SYSTEM RANK",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.38),
                      fontSize: Responsive.scaleText(context, 10),
                      letterSpacing: 2,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  Text(
                    "SENTINEL",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: Responsive.scaleText(context, 22),
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
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "LVL ${provider.currentLevel}",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
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
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
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
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            fontSize: Responsive.scaleText(context, 11),
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
          child: _buildGlow(theme.colorScheme.secondary.withOpacity(0.05)),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _buildGlow(theme.colorScheme.primary.withOpacity(0.05)),
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
              ? theme.colorScheme.primary.withOpacity(0.8)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.15),
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
