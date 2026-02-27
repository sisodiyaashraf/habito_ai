import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/hive_provider.dart';
import '../providers/habit_provider.dart';

// Ensure this matches your existing GlobalRank entity
class GlobalRank {
  final int position;
  final String username;
  final int level;
  final double disciplineIndex;
  final bool isUser;
  GlobalRank({
    required this.position,
    required this.username,
    required this.level,
    required this.disciplineIndex,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.watch<HiveProvider>();
    final habit = context.watch<HabitProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "RANKINGS_TERMINAL",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 10,
            color: Colors.cyanAccent,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelStyle: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelColor: Colors.white24,
          tabs: const [
            Tab(text: "LOCAL_SQUAD"),
            Tab(text: "GLOBAL_GRID"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSquadTab(hive, habit), _buildGlobalTab(habit)],
      ),
    );
  }

  // --- TAB 1: SQUAD LEADERBOARD (LOCAL AI) ---
  Widget _buildSquadTab(HiveProvider hive, HabitProvider habit) {
    List<Map<String, dynamic>> squadRanks = [
      {'name': 'YOU', 'xp': habit.totalXP, 'isUser': true},
      ...hive.members.map(
        (m) => {
          'name': m.displayName,
          'xp': (m.syncRate * 5000).toInt(),
          'isUser': false,
        },
      ),
    ];
    squadRanks.sort((a, b) => b['xp'].compareTo(a['xp']));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: squadRanks.length,
      itemBuilder: (context, index) {
        final rank = squadRanks[index];
        return FadeInLeft(
          delay: Duration(milliseconds: index * 50),
          child: _buildSimpleRankTile(
            index + 1,
            rank['name'],
            rank['xp'],
            rank['isUser'],
          ),
        );
      },
    );
  }

  // --- TAB 2: GLOBAL LEADERBOARD (MOCK/SERVER) ---
  Widget _buildGlobalTab(HabitProvider habit) {
    final List<GlobalRank> topSentinels = [
      GlobalRank(
        position: 1,
        username: "UNIT_ZERO",
        level: 99,
        disciplineIndex: 998.5,
      ),
      GlobalRank(
        position: 2,
        username: "NEO_SENTINEL",
        level: 85,
        disciplineIndex: 942.1,
      ),
      GlobalRank(
        position: 3,
        username: "DISCIPLINE_AI",
        level: 82,
        disciplineIndex: 910.4,
      ),
      GlobalRank(
        position: 1420,
        username: "MOHD ASHRAF",
        level: habit.currentLevel,
        disciplineIndex: habit.totalXP.toDouble(),
        isUser: true,
      ),
    ];

    return Column(
      children: [
        _buildUserStatusHeader(topSentinels.last),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: topSentinels.length - 1,
            itemBuilder: (context, index) => FadeInRight(
              delay: Duration(milliseconds: index * 100),
              child: _buildGlobalRankTile(topSentinels[index]),
            ),
          ),
        ),
      ],
    );
  }

  // --- SHARED UI COMPONENTS ---

  Widget _buildSimpleRankTile(int pos, String name, int xp, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.cyanAccent.withOpacity(0.05)
            : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUser ? Colors.cyanAccent.withOpacity(0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Text(
            "#$pos",
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.cyanAccent,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            "$xp XP",
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusHeader(GlobalRank user) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyanAccent.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "GLOBAL_POSITION",
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.cyanAccent,
                  fontSize: 8,
                ),
              ),
              Text(
                "#${user.position}",
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            "LEVEL ${user.level}",
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalRankTile(GlobalRank rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            "${rank.position}",
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white24,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            rank.username,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            "LVL ${rank.level}",
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.cyanAccent,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
