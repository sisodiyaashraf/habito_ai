import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/services/backup_service.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';

class NeuralBackupScreen extends StatefulWidget {
  const NeuralBackupScreen({super.key});

  @override
  State<NeuralBackupScreen> createState() => _NeuralBackupScreenState();
}

class _NeuralBackupScreenState extends State<NeuralBackupScreen> {
  bool _isSyncing = false;
  String _statusText = "STANDBY: NEURAL LINK READY";
  String _currentLog = "> IDLE";
  Timer? _logTimer;

  final List<String> _syncLogs = [
    "> INITIALIZING UPLINK...",
    "> ENCRYPTING NEURAL PACKETS...",
    "> BYPASSING FIREWALL...",
    "> SYNCING SENTINEL LVL...",
    "> ARCHIVING HIVE LOGS...",
    "> SECURING LEGACY VAULT...",
  ];

  void _startSync() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSyncing = true;
      _statusText = "UPLINK IN PROGRESS";
    });

    int logIndex = 0;
    _logTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _currentLog = _syncLogs[logIndex % _syncLogs.length];
          logIndex++;
        });
      }
    });

    final habitProvider = context.read<HabitProvider>();
    final aiProvider = context.read<AIProvider>();

    try {
      await BackupService().performNeuralSync(
        habits: habitProvider,
        ai: aiProvider,
      );
    } finally {
      _logTimer?.cancel();
      if (mounted) {
        HapticFeedback.vibrate();
        setState(() {
          _isSyncing = false;
          _statusText = "UPLINK COMPLETE: LEGACY SECURED";
          _currentLog = "> SESSION TERMINATED";
        });
      }
    }
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03050B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "NEURAL BACKUP",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulseIcon(),
              const SizedBox(height: 50),

              // Status Header (Orbitron)
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: _isSyncing ? Colors.cyanAccent : Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              // System Terminal Box (SpaceMono)
              Container(
                height: 60,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Text(
                  _currentLog,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: _isSyncing
                        ? Colors.cyanAccent.withOpacity(0.6)
                        : Colors.white10,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(height: 80),
              _buildSyncButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseIcon() {
    if (_isSyncing) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Pulse(
            infinite: true,
            duration: const Duration(seconds: 1),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withOpacity(0.05),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
              ),
            ),
          ),
          const Icon(
            Icons.cloud_upload_outlined,
            size: 80,
            color: Colors.cyanAccent,
          ),
        ],
      );
    }

    return FadeIn(
      child: Icon(
        Icons.cloud_done_outlined,
        size: 80,
        color: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSyncing ? null : _startSync,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent.withOpacity(0.1),
          disabledBackgroundColor: Colors.white.withOpacity(0.03),
          elevation: 0,
          side: BorderSide(
            color: _isSyncing
                ? Colors.white10
                : Colors.cyanAccent.withOpacity(0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          _isSyncing ? "SYNCING..." : "INITIATE UPLINK",
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: _isSyncing ? Colors.white24 : Colors.cyanAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
