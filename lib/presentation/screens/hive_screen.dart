import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// Providers
import '../providers/hive_provider.dart';
import '../providers/habit_provider.dart';

// Widgets
import '../widgets/SquadStatsWidget.dart';
import '../widgets/sentient_core.dart';
import '../widgets/hive_chat_terminal.dart';
import '../widgets/robot_guide_overlay.dart';

class HiveScreen extends StatefulWidget {
  const HiveScreen({super.key});

  @override
  State<HiveScreen> createState() => _HiveScreenState();
}

class _HiveScreenState extends State<HiveScreen> {
  // --- GUIDE STATE ENGINE ---
  bool _isGuideVisible = false;
  int _guideStepIndex = 0;

  // Walkthrough sequence
  final List<Map<String, String>> _hiveSequence = [
    {
      'label': 'HIVE_UPLINK',
      'message':
          'Welcome to the Hive, Operator. This is your shared neural network for squad synchronization.',
    },
    {
      'label': 'SQUAD_MISSION',
      'message':
          'Initialize or track active squad missions here. Collective efforts yield significantly higher system rewards.',
    },
    {
      'label': 'STABILITY_SYNC',
      'message':
          'Monitor Hive-wide stability. If total sync falls below critical levels, system glitches will propagate.',
    },
    {
      'label': 'ENCRYPTED_TERMINAL',
      'message':
          'This is your secure channel. Communicate with other operatives and monitor live system logs.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Trigger guide check after first build frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHiveGuide());
  }

  Future<void> _checkHiveGuide() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    bool shouldShow = await habitProvider.shouldShowGuide('hive');
    if (shouldShow && mounted) {
      setState(() {
        _isGuideVisible = true;
        _guideStepIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final bool isCritical = hive.hiveStability < 0.5;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- CRITICAL FIX: STABILIZE GUIDE POSITION ---
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Atmospheric Glow
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlow(
              context,
              isCritical
                  ? theme.colorScheme.error.withAlpha((0.12 * 255).toInt())
                  : theme.colorScheme.primary.withAlpha((0.08 * 255).toInt()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, hive),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- MISSION LOGIC (Highlight Step 1) ---
                        _buildHighlightWrapper(
                          context,
                          isActive: _isGuideVisible && _guideStepIndex == 1,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: hive.isMissionActive
                              ? FadeInDown(child: _buildMissionProgress(context, hive))
                              : FadeInDown(
                                  child: _buildMissionDispatcher(context, hive),
                                ),
                        ),

                        // --- SQUADRON RADAR HUD ---
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: FadeInDown(
                            delay: const Duration(milliseconds: 100),
                            child: const SquadStatsWidget(),
                          ),
                        ),

                        // --- SYSTEM STABILITY HUD (Highlight Step 2) ---
                        _buildHighlightWrapper(
                          context,
                          isActive: _isGuideVisible && _guideStepIndex == 2,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FadeInDown(
                            delay: const Duration(milliseconds: 150),
                            child: _buildStabilityCard(context, hive),
                          ),
                        ),

                        _buildSectionLabel(context, "ACTIVE SQUADRON", isCritical),
                        FadeInUp(child: _buildMemberGrid(context, hive)),

                        const SizedBox(height: 25),

                        // --- TERMINAL (Highlight Step 3) ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildSectionLabelTerminal(context),
                        ),
                        const SizedBox(height: 10),

                        _buildHighlightWrapper(
                          context,
                          isActive: _isGuideVisible && _guideStepIndex == 3,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Container(
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt())),
                              color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
                            ),
                            child: const ClipRRect(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                              child: HiveChatTerminal(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- SENTINEL GUIDE OVERLAY ---
          if (_isGuideVisible)
            RobotGuideOverlay(
              label: _hiveSequence[_guideStepIndex]['label']!,
              message: _hiveSequence[_guideStepIndex]['message']!,
              onDismiss: () {
                setState(() {
                  if (_guideStepIndex < _hiveSequence.length - 1) {
                    _guideStepIndex++;
                    HapticFeedback.lightImpact();
                  } else {
                    _isGuideVisible = false;
                    context.read<HabitProvider>().markGuideAsSeen('hive');
                    HapticFeedback.mediumImpact();
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  // --- HIGHLIGHT SYSTEM (Stationary implementation for UI stability) ---
  Widget _buildHighlightWrapper(
    BuildContext context, {
    required Widget child,
    required bool isActive,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withAlpha((0.8 * 255).toInt())
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildHeader(BuildContext context, HiveProvider hive) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    hive.copyProtocolToClipboard();
                    HapticFeedback.lightImpact();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "UPLINK: ${hive.currentHiveId ?? 'DISCONNECTED'}",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: theme.colorScheme.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.copy_rounded,
                        color: theme.colorScheme.primary,
                        size: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "HIVE: ${hive.hiveName}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SentientCore(),
        ],
      ),
    );
  }

  Widget _buildMemberGrid(BuildContext context, HiveProvider hive) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: hive.members.length,
      itemBuilder: (context, index) {
        final member = hive.members[index];
        return Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                member.displayName[0],
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member.displayName.split(' ')[0],
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 7,
                fontFamily: 'SpaceMono',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title, bool isCritical) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          Icon(
            Icons.sensors,
            color: isCritical ? theme.colorScheme.error : theme.colorScheme.primary,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabelTerminal(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      "LIVE ENCRYPTED UPLINK",
      style: TextStyle(
        fontFamily: 'Orbitron',
        color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
      ),
    );
  }

  Widget _buildGlow(BuildContext context, Color color) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)],
      ),
    );
  }

  Widget _buildMissionDispatcher(BuildContext context, HiveProvider hive) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => hive.dispatchMission(context, "SYNC 50 PROTOCOLS"),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha((0.05 * 255).toInt()),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            "INITIALIZE SQUAD MISSION",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: theme.colorScheme.primary,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionProgress(BuildContext context, HiveProvider hive) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt())),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MISSION: ${hive.activeMissionGoal}",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                  fontSize: 8,
                ),
              ),
              Text(
                "${(hive.collectiveMissionProgress * 100).toInt()}%",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: hive.collectiveMissionProgress,
            backgroundColor: theme.colorScheme.surfaceContainer,
            color: theme.colorScheme.primary,
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityCard(BuildContext context, HiveProvider hive) {
    final theme = Theme.of(context);
    final bool isCritical = hive.hiveStability < 0.5;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCritical
            ? theme.colorScheme.error.withValues(alpha: 0.1)
            : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical
              ? theme.colorScheme.error.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            hive.systemStatus,
            style: TextStyle(
              color: isCritical
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceMono',
            ),
          ),
          Text(
            "${(hive.hiveStability * 100).toInt()}% SYNC",
            style: TextStyle(
              color: isCritical
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }
}
