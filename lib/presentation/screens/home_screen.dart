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
import '../widgets/WeeklyRecapCard.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/futuristic_nav_bar.dart';
import '../widgets/weekly_progress_chart.dart';
import '../widgets/empty_habits_view.dart';
import '../widgets/sentient_core.dart';
import '../widgets/achievement_overlay.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/session_sheet.dart';
import '../widgets/SessionTimerWidget.dart';
import 'GameHubScreen.dart';
import 'HiveScreen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // CRITICAL: Initialize neural links immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recalibrateNeuralSystems();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns from background, refresh the nudge schedule
    if (state == AppLifecycleState.resumed) {
      _recalibrateNeuralSystems();
    }
  }

  Future<void> _recalibrateNeuralSystems() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final hiveProvider = Provider.of<HiveProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    await habitProvider.loadHabits();

    // Sync rotation engine with current active persona and habit list
    if (mounted) {
      await notificationProvider.scheduleDailySmartNudges(
        habitProvider.habits,
        hiveProvider.activePersona,
      );
    }
    debugPrint("SYSTEM: Neural Nudge protocols synchronized.");
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();

    // Dynamic System Color Mapping
    final Color systemColor = hive.hiveStability < 0.3
        ? Colors.redAccent
        : (hive.hiveStability < 0.6 ? Colors.orangeAccent : Colors.cyanAccent);

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF03050B),
      floatingActionButton: _currentNavIndex == 0
          ? FadeInUp(
              child: FloatingActionButton(
                onPressed: () {
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
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.black,
                    size: 35,
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
          const AchievementOverlay(),
          const LevelUpOverlay(),
        ],
      ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildGlassContainer(child: const AIInsightCard()),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 25)),

          // --- ANALYTICS SECTOR ---
          SliverToBoxAdapter(
            child: FadeInUp(child: const WeeklyProgressChart()),
          ),
          SliverToBoxAdapter(
            child: FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: const WeeklyRecapCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(25, 35, 25, 15),
              child: Text(
                "ACTIVE PROTOCOLS",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          Consumer<HabitProvider>(
            builder: (context, provider, _) {
              if (provider.habits.isEmpty) {
                return const SliverFillRemaining(child: EmptyHabitsView());
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final habit = provider.habits[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 40),
                      child: habit.isTimerEnabled
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: SessionTimerWidget(habit: habit),
                            )
                          : _buildHyperHabitCard(context, habit, systemColor),
                    );
                  }, childCount: provider.habits.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  Widget _buildHyperHabitCard(
    BuildContext context,
    dynamic habit,
    Color systemColor,
  ) {
    final bool isCompleted = habit.isGoalMet(DateTime.now());
    final Color cardAccent = isCompleted ? systemColor : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: _buildGlassContainer(
        opacity: isCompleted ? 0.12 : 0.05,
        borderColor: isCompleted
            ? systemColor.withOpacity(0.5)
            : Colors.white.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            HapticFeedback.mediumImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SessionSheet(habit: habit),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildProgressRing(
                  habit.progressPercent,
                  isCompleted,
                  systemColor,
                  Icons.bolt_rounded,
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildMiniBadge(
                            habit.category.toUpperCase(),
                            systemColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCompleted ? "SYNC COMPLETE" : "AWAITING UPLINK",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              color: isCompleted ? systemColor : Colors.white38,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: systemColor.withOpacity(0.2),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(Color systemColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "NEURAL-OS-V2",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: systemColor.withOpacity(0.5),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "COMMAND HUB",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SentientCore(),
        ],
      ),
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
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressRing(
    double progress,
    bool isCompleted,
    Color systemColor,
    IconData icon,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? systemColor : systemColor.withOpacity(0.3),
            ),
          ),
        ),
        Icon(
          isCompleted ? Icons.check_circle_rounded : icon,
          color: isCompleted ? systemColor : Colors.white24,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildCyberGrid() {
    return Opacity(
      opacity: 0.1,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://www.transparenttextures.com/patterns/carbon-fibre.png',
            ),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    double opacity = 0.05,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.1),
            ),
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
