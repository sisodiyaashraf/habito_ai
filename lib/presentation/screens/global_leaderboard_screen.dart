import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/hive_provider.dart';
import '../providers/habit_provider.dart';

class GlobalRank {
  final int position;
  final String username;
  final int level;
  final int xp;
  final bool isUser;
  final String callsign;

  GlobalRank({
    required this.position,
    required this.username,
    required this.level,
    required this.xp,
    required this.callsign,
    this.isUser = false,
  });
}

class GlobalLeaderboardScreen extends StatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  State<GlobalLeaderboardScreen> createState() =>
      _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState extends State<GlobalLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final habit = context.watch<HabitProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "RANKINGS_TERMINAL",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary, size: 20),
            onPressed: () {
              HapticFeedback.heavyImpact();
              context.read<HiveProvider>().sendMessage("NEURAL_SCAN: REFRESHING GLOBAL GRID DATA...", sender: "SYSTEM");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.9),
                  content: const Text("NEURAL_SCAN_COMPLETE // GRID_SYNCED", style: TextStyle(fontFamily: 'SpaceMono', fontSize: 10, color: Colors.black)),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          labelColor: theme.colorScheme.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          tabs: const [
            Tab(text: "SQUAD_SYNC"),
            Tab(text: "GLOBAL_GRID"),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withValues(alpha: 0.02),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildSquadTab(hive, habit, theme),
                  _buildGlobalTab(habit, theme),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildSystemTicker(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemTicker(ThemeData theme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            border: Border(top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "NEURAL_UPLINK: ACTIVE // ENCRYPTED_SYNC_STABLE // NO_LATENCY_DETECTED",
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                "v2.0.99",
                style: TextStyle(fontFamily: 'SpaceMono', color: theme.colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquadTab(HiveProvider hive, HabitProvider habit, ThemeData theme) {
    List<Map<String, dynamic>> squadRanks = [
      {'name': hive.userName, 'xp': habit.totalXP, 'isUser': true, 'lvl': habit.currentLevel},
      ...hive.members.map(
        (m) => {
          'name': m.displayName,
          'xp': (m.syncRate * 5000).toInt(),
          'isUser': false,
          'lvl': (m.syncRate * 20).toInt() + 1,
        },
      ),
    ];
    squadRanks.sort((a, b) => b['xp'].compareTo(a['xp']));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: squadRanks.length,
      itemBuilder: (context, index) {
        final rank = squadRanks[index];
        return FadeInLeft(
          delay: Duration(milliseconds: index * 50),
          child: _buildRankTile(
            index + 1,
            rank['name'],
            rank['xp'],
            rank['lvl'],
            rank['isUser'],
            theme,
          ),
        );
      },
    );
  }

  Widget _buildGlobalTab(HabitProvider habit, ThemeData theme) {
    final List<GlobalRank> topSentinels = [
      GlobalRank(position: 1, username: "UNIT_ZERO", callsign: "VOID-RUNNER", level: 99, xp: 125400, isUser: false),
      GlobalRank(position: 2, username: "NEO_SENTINEL", callsign: "CORE-X", level: 85, xp: 98200, isUser: false),
      GlobalRank(position: 3, username: "DISCIPLINE_AI", callsign: "WARDEN-01", level: 82, xp: 84100, isUser: false),
      GlobalRank(position: 4, username: "CYBER_GHOST", callsign: "STEALTH-09", level: 78, xp: 76500, isUser: false),
      GlobalRank(position: 5, username: "VECTOR_7", callsign: "NEON-SOUL", level: 75, xp: 71200, isUser: false),
    ];

    final userRank = GlobalRank(
      position: 1420 - (habit.totalXP ~/ 100),
      username: "YOU",
      callsign: "SENTINEL-01",
      level: habit.currentLevel,
      xp: habit.totalXP,
      isUser: true,
    );

    return Column(
      children: [
        _buildUserStatusHeader(userRank, theme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            children: [
              Text("TOP_SENTINELS", style: TextStyle(fontFamily: 'Orbitron', color: theme.colorScheme.primary.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 2)),
              const Spacer(),
              Text("SYSTEM_ACTIVE", style: TextStyle(fontFamily: 'SpaceMono', color: Colors.greenAccent.withValues(alpha: 0.5), fontSize: 8)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: topSentinels.length,
            itemBuilder: (context, index) => FadeInUp(
              delay: Duration(milliseconds: index * 100),
              child: _buildGlobalRankTile(topSentinels[index], theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankTile(int pos, String name, int xp, int lvl, bool isUser, ThemeData theme) {
    final color = isUser ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUser ? color.withValues(alpha: 0.08) : theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUser ? color.withValues(alpha: 0.5) : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: isUser ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              "#$pos",
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          name.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: theme.colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        subtitle: Text(
          "LVL $lvl SENTINEL",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 8,
          ),
        ),
        trailing: Text(
          "$xp XP",
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: color.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatusHeader(GlobalRank user, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary.withValues(alpha: 0.5), Colors.transparent, theme.colorScheme.primary.withValues(alpha: 0.2)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: theme.colorScheme.surface.withValues(alpha: 0.7),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GLOBAL_UPLINK_POS",
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: theme.colorScheme.primary,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "#${user.position}",
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: theme.colorScheme.onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "PERCENTILE",
                        style: TextStyle(fontFamily: 'SpaceMono', color: theme.colorScheme.primary, fontSize: 7),
                      ),
                      Text(
                        "TOP 2.4%",
                        style: TextStyle(fontFamily: 'Orbitron', color: theme.colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalRankTile(GlobalRank rank, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showNeuralDossier(context, rank);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                "${rank.position}",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: rank.position <= 3 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.username,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  rank.callsign,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    fontSize: 7,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "LVL ${rank.level}",
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${rank.xp} XP",
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.1), size: 12),
          ],
        ),
      ),
    );
  }

  void _showNeuralDossier(BuildContext context, GlobalRank rank) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dossier",
      pageBuilder: (context, anim1, anim2) {
        final color = rank.position <= 3 ? Colors.amberAccent : Colors.cyanAccent;
        return Center(
          child: FadeInScale(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.1),
                      ),
                      child: Icon(Icons.security_rounded, color: color, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      rank.username,
                      style: TextStyle(fontFamily: 'Orbitron', color: color, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    Text(
                      rank.callsign,
                      style: TextStyle(fontFamily: 'SpaceMono', color: color.withValues(alpha: 0.5), fontSize: 10),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Colors.white10),
                    ),
                    _buildDossierRow("STATUS", "ACTIVE_DUTY", Colors.greenAccent),
                    _buildDossierRow("LEVEL", "${rank.level}", color),
                    _buildDossierRow("XP_TOTAL", "${rank.xp}", color),
                    _buildDossierRow("RANK", "#${rank.position}", color),
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CLOSE_DOSSIER", style: TextStyle(fontFamily: 'Orbitron', color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDossierRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'SpaceMono', color: Colors.white24, fontSize: 10)),
          Text(value, style: TextStyle(fontFamily: 'SpaceMono', color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class FadeInScale extends StatefulWidget {
  final Widget child;
  const FadeInScale({super.key, required this.child});

  @override
  State<FadeInScale> createState() => _FadeInScaleState();
}

class _FadeInScaleState extends State<FadeInScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale, child: widget.child));
  }
}
