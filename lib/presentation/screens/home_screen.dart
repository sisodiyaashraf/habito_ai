import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// Core Providers
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';
import '../providers/notification_provider.dart';

// Widgets & Screens
import '../widgets/session_sheet.dart';
import '../widgets/weekly_recap_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/futuristic_nav_bar.dart';
import '../widgets/weekly_progress_chart.dart';
import '../widgets/empty_habits_view.dart';
import '../widgets/sentient_core.dart';
import '../widgets/achievement_overlay.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/session_timer_widget.dart';
import '../widgets/robot_guide_overlay.dart';
import '../../core/utils/responsive.dart';
import 'game_hub_screen.dart';
import 'hive_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;

  // --- ANIMATION ENGINE ---
  late AnimationController _spinController;

  // --- GUIDE STATE ENGINE ---
  bool _isGuideVisible = false;
  int _guideStepIndex = 0;
  bool _isInitialSyncComplete = false;

  final List<Map<String, String>> _coreSequence = [
    {
      'label': 'COMMAND_HUB',
      'message': 'Welcome back, Operator. This is your Neural command center. Let us calibrate your interface.',
    },
    {
      'label': 'NEURAL_INSIGHTS',
      'message': 'This sector uses AI to analyze your behavioral patterns and provide real-time optimization strategies.',
    },
    {
      'label': 'STABILITY_LOG',
      'message': 'This telemetry chart tracks your sync consistency. Maintain high stability to prevent system glitches.',
    },
    {
      'label': 'ACTIVE_PROTOCOLS',
      'message': 'These are your primary habits. Tap any protocol to initiate a session and upload progress.',
    },
    {
      'label': 'ADD_PROTOCOL',
      'message': 'Use the pulse-button to initiate a new neural protocol and expand system capabilities.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performInitialSystemSync();
      }
    });
  }

  Future<void> _performInitialSystemSync() async {
    await _recalibrateNeuralSystems();
    await _checkSentinelGuide();
    if (mounted) {
      setState(() => _isInitialSyncComplete = true);
    }
  }

  Future<void> _checkSentinelGuide() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    bool shouldShow = await habitProvider.shouldShowGuide('core');
    if (shouldShow && mounted) {
      setState(() {
        _isGuideVisible = true;
        _guideStepIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalibrateNeuralSystems();
    }
  }

  Future<void> _recalibrateNeuralSystems() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final hiveProvider = Provider.of<HiveProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    await habitProvider.loadHabits();

    if (mounted) {
      await notificationProvider.scheduleDailySmartNudges(
        habitProvider.habits,
        hiveProvider.activePersona,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final Color systemColor = hive.hiveStability < 0.3
        ? Colors.redAccent
        : (hive.hiveStability < 0.6 ? Colors.orangeAccent : Colors.cyanAccent);

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      floatingActionButton: _currentNavIndex == 0
          ? FadeInUp(
              child: _buildHighlightWrapper(
                isActive: _isGuideVisible && _guideStepIndex == 4,
                isCircular: true,
                child: GestureDetector(
                  onLongPressStart: (_) {
                    if (_isGuideVisible) return;
                    HapticFeedback.mediumImpact();
                    _spinController.repeat();
                  },
                  onLongPressEnd: (_) {
                    _spinController.stop();
                    _spinController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  },
                  child: FloatingActionButton(
                    onPressed: () {
                      if (_isGuideVisible) return;
                      HapticFeedback.heavyImpact();
                      AddHabitSheet.show(context);
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [systemColor, systemColor.withOpacity(0.4)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: systemColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: RotationTransition(
                        turns: _spinController,
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.black,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      bottomNavigationBar: FuturisticNavBar(
        selectedIndex: _currentNavIndex,
        onItemSelected: (index) {
          HapticFeedback.lightImpact();
          setState(() => _currentNavIndex = index);
        },
      ),
      body: Stack(
        children: [
          _buildCyberGrid(),
          Positioned(
            top: -150,
            right: -100,
            child: _buildGlowSphere(systemColor.withOpacity(0.08), 400),
          ),
          IndexedStack(
            index: _currentNavIndex,
            children: [
              _buildDashboard(context, systemColor),
              const HistoryScreen(),
              const GameHubScreen(),
              const ProfileScreen(),
              const HiveScreen(),
            ],
          ),

          if (_currentNavIndex == 0 && _isGuideVisible)
            RobotGuideOverlay(
              label: _coreSequence[_guideStepIndex]['label']!,
              message: _coreSequence[_guideStepIndex]['message']!,
              onDismiss: () {
                setState(() {
                  if (_guideStepIndex < _coreSequence.length - 1) {
                    _guideStepIndex++;
                    HapticFeedback.lightImpact();
                  } else {
                    _isGuideVisible = false;
                    context.read<HabitProvider>().markGuideAsSeen('core');
                    HapticFeedback.mediumImpact();
                  }
                });
              },
            ),

          const AchievementOverlay(),
          const LevelUpOverlay(),
        ],
      ),
    );
  }

  Widget _buildHighlightWrapper({
    required Widget child,
    required bool isActive,
    bool isCircular = false,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: padding,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(30),
        border: Border.all(
          color: isActive
              ? Colors.cyanAccent.withOpacity(0.8)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  Widget _buildDashboard(BuildContext context, Color systemColor) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeInDown(child: _buildHeader(systemColor)),
          ),
          SliverToBoxAdapter(
            child: _buildHighlightWrapper(
              isActive: _isGuideVisible && _guideStepIndex == 1,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildGlassContainer(child: const AIInsightCard()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 25)),
          SliverToBoxAdapter(
            child: _buildHighlightWrapper(
              isActive: _isGuideVisible && _guideStepIndex == 2,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const WeeklyProgressChart(),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: const WeeklyRecapCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.scalePadding(context, 25),
                35,
                Responsive.scalePadding(context, 25),
                15,
              ),
              child: Text(
                "ACTIVE PROTOCOLS",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: Responsive.scaleText(context, 10),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          Consumer<HabitProvider>(
            builder: (context, provider, _) {
              if (!_isInitialSyncComplete && provider.habits.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                );
              }
              if (provider.habits.isEmpty) {
                return const SliverFillRemaining(child: EmptyHabitsView());
              }

              final now = DateTime.now();
              final activeHabits = provider.habits.where((h) => !h.isGoalMet(now) && !h.isTerminatedOn(now)).toList();
              final completedHabits = provider.habits.where((h) => h.isGoalMet(now) || h.isTerminatedOn(now)).toList();

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightWrapper(
                        isActive: _isGuideVisible && _guideStepIndex == 3,
                        child: activeHabits.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: systemColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: systemColor.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.verified_rounded, color: systemColor, size: 36),
                                    const SizedBox(height: 12),
                                    Text(
                                      "ALL PROTOCOLS SYNCHRONIZED",
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        color: systemColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Neural system operating at maximum efficiency for today.",
                                      style: TextStyle(
                                        fontFamily: 'SpaceMono',
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        fontSize: 9,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: activeHabits.map((habit) {
                                  return FadeInUp(
                                    duration: const Duration(milliseconds: 400),
                                    child: _buildHyperHabitCard(context, habit, systemColor),
                                  );
                                }).toList(),
                              ),
                      ),
                      if (completedHabits.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Text(
                              "COMPLETED PROTOCOLS TODAY",
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: Responsive.scaleText(context, 9),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: systemColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${completedHabits.length}",
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: systemColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Column(
                          children: completedHabits.map((habit) {
                            return _buildHyperHabitCard(context, habit, systemColor);
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      ),
    );
  }

  Widget _buildHyperHabitCard(BuildContext context, dynamic habit, Color systemColor) {
    final theme = Theme.of(context);
    final bool isCompleted = habit.isGoalMet(DateTime.now());
    final bool isTerminated = habit.isTerminatedOn(DateTime.now());
    final Color cardAccent = isCompleted
        ? systemColor
        : (isTerminated ? Colors.redAccent : theme.colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Dismissible(
        key: Key("habit_dismiss_${habit.id}"),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          HapticFeedback.heavyImpact();
          return await _showDeleteConfirmationDialog(context, habit.name, habit.id);
        },
        onDismissed: (direction) {
          context.read<HabitProvider>().deleteHabit(habit.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "PROTOCOL '${habit.name.toUpperCase()}' PURGED FROM VAULT",
                style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 25),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "PURGE PROTOCOL",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            ],
          ),
        ),
        child: _buildGlassContainer(
          opacity: isCompleted ? 0.12 : (isTerminated ? 0.08 : 0.05),
          borderColor: isCompleted
              ? systemColor.withValues(alpha: 0.5)
              : (isTerminated
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              if (_isGuideVisible) return;
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SessionSheet(habit: habit),
              );
            },
            onLongPress: () {
              if (_isGuideVisible) return;
              HapticFeedback.heavyImpact();
              _showDeleteConfirmationDialog(context, habit.name, habit.id).then((confirmed) {
                if (confirmed == true) {
                  context.read<HabitProvider>().deleteHabit(habit.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      context.read<HabitProvider>().toggleHabit(habit.id, context);
                    },
                    child: _buildProgressRing(
                      habit.progressPercent,
                      isCompleted,
                      isTerminated ? Colors.redAccent : systemColor,
                      isTerminated ? Icons.cancel_outlined : Icons.bolt_rounded,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: cardAccent,
                            fontSize: Responsive.scaleText(context, 12),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildMiniBadge(
                              habit.category.toUpperCase(),
                              isTerminated ? Colors.redAccent : systemColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isCompleted
                                  ? "SYNC COMPLETE"
                                  : (isTerminated ? "PROTOCOL TERMINATED" : "AWAITING UPLINK"),
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                color: isCompleted
                                    ? systemColor
                                    : (isTerminated
                                        ? Colors.redAccent
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                                fontSize: Responsive.scaleText(context, 8),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: systemColor.withValues(alpha: 0.2), size: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String name, String id) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Text(
              "PURGE PROTOCOL",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.redAccent,
                fontSize: Responsive.scaleText(context, 13),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently purge '${name.toUpperCase()}' from local neural storage? This action cannot be reversed.",
          style: const TextStyle(fontFamily: 'SpaceMono', color: Colors.white70, fontSize: 10),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ABORT", style: TextStyle(fontFamily: 'SpaceMono', color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("PURGE DATA", style: TextStyle(fontFamily: 'Orbitron', color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color systemColor) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.scalePadding(context, 20),
            20,
            Responsive.scalePadding(context, 20),
            15,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "NEURAL-OS-V2 // ACTIVE",
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            color: systemColor.withValues(alpha: 0.6),
                            fontSize: Responsive.scaleText(context, 8),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "COMMAND HUB",
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: theme.colorScheme.onSurface,
                            fontSize: Responsive.scaleText(context, 20),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SentientCore(),
                ],
              ),
              const SizedBox(height: 16),
              // TELEMETRY & PROGRESS HUD CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: systemColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: systemColor.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: systemColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "LVL ${provider.currentLevel} [${provider.totalXP} XP]",
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                color: systemColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${(provider.levelProgress * 100).toInt()}% UPLINK",
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: provider.levelProgress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(systemColor),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeaderMetricTile("STREAK", "${provider.highestStreak}D", Icons.whatshot_rounded, Colors.orangeAccent),
                        _buildHeaderMetricTile("SYNC RATE", "${(provider.averageCompletionRate * 100).toInt()}%", Icons.sync_rounded, Colors.greenAccent),
                        _buildHeaderMetricTile("STABILITY", "${(provider.weekStability * 100).toInt()}%", Icons.auto_graph_rounded, Colors.purpleAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderMetricTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: color.withValues(alpha: 0.6),
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          color: color,
          fontSize: Responsive.scaleText(context, 7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressRing(double progress, bool isCompleted, Color systemColor, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? systemColor : systemColor.withOpacity(0.3)),
          ),
        ),
        Icon(
          isCompleted ? Icons.check_circle_rounded : icon,
          color: isCompleted ? systemColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildCyberGrid() {
    return Opacity(
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface.withOpacity(0.1), BlendMode.srcATop),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, double opacity = 0.05, Color? borderColor}) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(opacity),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor ?? theme.colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlowSphere(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 60)],
      ),
    );
  }
}
