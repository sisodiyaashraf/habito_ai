import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/history_analytics_header.dart';
import '../widgets/mood_trend_chart.dart';
import 'neural_archive_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch logs for real-time UI updates
    final habitProvider = context.watch<HabitProvider>();
    final logs = habitProvider.systemLogs;

    return Scaffold(
      backgroundColor: const Color(0xFF03050B), // Unified background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Custom close button below
        title: const Text(
          "MISSION VAULT",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: Colors.cyanAccent,
              size: 20,
            ),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus(); // Neural Fix
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NeuralArchiveScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. REAL-TIME SYNC STATUS
          _buildSyncIndicator(habitProvider.habits.isNotEmpty),

          // 2. Lifetime Metrics Summary
          const HistoryAnalyticsHeader(),

          // 3. Neural Stability Graph
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: MoodTrendChart(),
          ),

          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // 4. Chronological Protocol Logs
          Expanded(
            child: logs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: logs.length,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogEntry(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator(bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.cyanAccent : Colors.white10,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? "NEURAL LINK: SYNCHRONIZED" : "LINK OFFLINE",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 8,
              color: isActive
                  ? Colors.cyanAccent.withOpacity(0.6)
                  : Colors.white10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), // Increased for visibility
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(log['icon'], color: Colors.cyanAccent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (log['title'] as String).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log['description'],
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('HH:mm | dd MMM').format(log['timestamp']),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 9,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            color: Colors.white.withOpacity(0.1),
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            "VAULT EMPTY: NO LOGS DETECTED",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white24,
              letterSpacing: 2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
