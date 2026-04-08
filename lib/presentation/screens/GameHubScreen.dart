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
import '../widgets/RobotGuideOverlay.dart';

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

    // FIX: Refined filtering to catch all rewards and separate by collection status
    final pendingLogs = habitProvider.systemLogs.where((log) {
      return log['reward_bot_id'] != null && log['is_collected'] != true;
    }).toList();

    final collectedLogs = habitProvider.systemLogs.where((log) {
      return log['reward_bot_id'] != null && log['is_collected'] == true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(
        0xFF03050B,
      ), // Solid Matte Black for continuity
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildAmbientGlows(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),

                // 1. Hive Status
                SliverToBoxAdapter(
                  child: _buildHighlightWrapper(
                    isActive: _isGuideVisible && _guideStepIndex == 1,
                    child: FadeInDown(
                      child: _buildHiveStatusCard(hiveProvider),
                    ),
                  ),
                ),

                // 2. Level Card
                SliverToBoxAdapter(
                  child: _buildHighlightWrapper(
                    isActive: _isGuideVisible && _guideStepIndex == 2,
                    child: FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      child: _buildLevelCard(habitProvider),
                    ),
                  ),
                ),

                // --- TAB SWITCHER ---
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
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

                // 3. Conditional Grid (Uplinks vs Vault)
                if (!_showVault)
                  pendingLogs.isEmpty
                      ? _buildEmptyState(
                          "NO PENDING UPLINKS\nComplete protocols to generate data packs.",
                        )
                      : _buildRewardGrid(pendingLogs, isVault: false)
                else
                  collectedLogs.isEmpty
                      ? _buildEmptyState(
                          "NEURAL VAULT EMPTY\nCollected cards will be archived here.",
                        )
                      : _buildRewardGrid(collectedLogs, isVault: true),

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
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardGrid(List<dynamic> logs, {required bool isVault}) {
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
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: _buildRewardCard(context, logs[index], isVault),
          );
        }, childCount: logs.length),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, dynamic log, bool isVault) {
    final String botId = log['reward_bot_id'];
    final reward = RewardGenerator.getByName(botId);

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        // Fire static show method with timestamp handshake
        RewardScratchDialog.show(context, reward, log['timestamp']);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: isVault
                ? Colors.white.withOpacity(0.02)
                : Colors.cyanAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isVault
                  ? Colors.white10
                  : Colors.cyanAccent.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isVault)
                Image.asset(
                  reward.frontImagePath,
                  height: 80,
                  fit: BoxFit.contain,
                )
              else
                Pulse(
                  infinite: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.cyanAccent,
                      size: 35,
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              Text(
                isVault ? reward.botName.toUpperCase() : "ENCRYPTED PACK",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isVault ? "DECRYPTED_SENTINEL" : "TAP TO DECRYPT",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: isVault
                      ? Colors.white24
                      : Colors.cyanAccent.withOpacity(0.5),
                  fontSize: 7,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EXISTING UI BUILDERS ---

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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SYSTEM RANK",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  Text(
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

  Widget _buildHighlightWrapper({
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
              ? Colors.cyanAccent.withOpacity(0.8)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.15),
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
