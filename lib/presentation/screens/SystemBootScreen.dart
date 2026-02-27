import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/hive_provider.dart';

class SystemBootScreen extends StatefulWidget {
  const SystemBootScreen({super.key});

  @override
  State<SystemBootScreen> createState() => _SystemBootScreenState();
}

class _SystemBootScreenState extends State<SystemBootScreen> {
  String _bootStatus = "INITIALIZING CORE...";
  double _progress = 0.0;
  final List<String> _logs = [
    "> VESTIGE OS v4.2.0",
    "> NEURAL_LINK: PENDING",
    "> LOCAL_DB: CONNECTING",
  ];

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  void _startBootSequence() async {
    // Phase 1: Establish Data Links
    await Future.delayed(const Duration(milliseconds: 800));
    _updateStatus(
      "ESTABLISHING NEURAL UPLINK...",
      "> UPLINK_PROTOCOL: SECURED",
    );

    // Phase 2: Load Hive & Habits
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      await context.read<HabitProvider>().loadHabits();
      await context.read<HiveProvider>().loadHiveSettings();
    }
    _updateStatus("SYNCHRONIZING PROTOCOLS...", "> DATA_VAULT: ONLINE");

    // Phase 3: Final Verification
    await Future.delayed(const Duration(milliseconds: 1000));
    _updateStatus("SENTIENT_CORE: ACTIVE", "> ALL SYSTEMS OPERATIONAL");

    // Launch into App
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  void _updateStatus(String status, String log) {
    setState(() {
      _bootStatus = status;
      _logs.add(log);
      _progress += 0.33;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03050B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Core Pulsing Logo
            Center(
              child: Pulse(
                infinite: true,
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.cyanAccent,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 60),

            // 2. Tactical Log Feed
            Container(
              height: 100,
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => FadeInLeft(
                  child: Text(
                    _logs[index],
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Status & Progress
            Text(
              _bootStatus,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.cyanAccent,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: Colors.cyanAccent,
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }
}
