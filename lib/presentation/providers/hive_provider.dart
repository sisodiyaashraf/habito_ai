import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/hive_member.dart';
import '../widgets/MissionLaunchOverlay.dart';
import '../widgets/MissionSuccessGlitch.dart';
import '../../core/services/personality_constants.dart';

class HiveProvider extends ChangeNotifier {
  // --- Core State ---
  List<HiveMember> _members = [];
  final List<Map<String, dynamic>> _hiveLogs = [];
  final List<Map<String, String>> _messages = [
    {
      "sender": "SYSTEM",
      "text": "ENCRYPTED UPLINK ESTABLISHED. GHOST NODES ONLINE.",
    },
  ];

  // --- Simulated Squad (Ghost Nodes) ---
  final List<Map<String, String>> _ghostNodes = [
    {"id": "G-01", "name": "VECTOR-7", "persona": "Competitive"},
    {"id": "G-02", "name": "NEON-SOUL", "persona": "Supportive"},
    {"id": "G-03", "name": "VOID-WALKER", "persona": "Stoic"},
  ];

  // --- Identity & Personality ---
  String _userName = "MOHD ASHRAF";
  HandlerPersona _activePersona = HandlerPersona.system;

  // --- HUD & Animation States ---
  bool _isSystemGlitching = false;
  String? _activePingId;
  String? _currentHiveId;

  // --- Mission System ---
  double _collectiveMissionProgress = 0.0;
  String _activeMissionGoal = "SYNC 50 PROTOCOLS";
  bool _isMissionActive = false;

  // --- Getters ---
  HandlerPersona get activePersona => _activePersona;
  String? get currentHiveId => _currentHiveId;
  String? get activePingId => _activePingId;
  bool get isSystemGlitching => _isSystemGlitching;
  String get userName => _userName;
  String get hiveName => "SENTINEL-ZERO";
  List<HiveMember> get members => _members;
  List<Map<String, dynamic>> get hiveLogs => _hiveLogs;
  List<Map<String, String>> get messages => List.from(_messages.reversed);
  double get collectiveMissionProgress => _collectiveMissionProgress;
  String get activeMissionGoal => _activeMissionGoal;
  bool get isMissionActive => _isMissionActive;

  // --- Neural Analytics Getters ---

  double get stability => hiveStability * 100;
  double get strain => systemStrain * 100;

  double get hiveStability {
    if (_members.isEmpty) return 1.0;
    double total = _members.fold(0.0, (sum, member) => sum + member.syncRate);
    return (total / _members.length).clamp(0.0, 1.0);
  }

  double get systemStrain {
    if (_members.isEmpty) return 0.0;
    double offlineFactor =
        _members.where((m) => !m.isOnline).length / _members.length;
    double efficiencyStrain =
        _members.where((m) => m.isOnline && m.syncRate < 0.5).length /
        _members.length;
    return (offlineFactor * 0.7 + efficiencyStrain * 0.3).clamp(0.0, 1.0);
  }

  double get calculateHeat {
    if (_members.isEmpty) return 0.0;
    double stabilityHeat = (1.0 - hiveStability) * 60;
    double missionFactor = _isMissionActive
        ? 10.0 + (collectiveMissionProgress * 30)
        : 5.0;
    return (stabilityHeat + missionFactor).clamp(0.0, 100.0);
  }

  List<double> get squadPerformanceData {
    if (_members.isEmpty) return [0.5, 0.5, 0.5, 0.5];
    return _members.map((m) => m.syncRate).toList();
  }

  Map<String, String> get memberBadges {
    Map<String, String> badges = {};
    for (var member in _members) {
      if (!member.isOnline || member.syncRate < 0.3)
        badges[member.id] = "⚠️ OFFLINE";
      else if (member.syncRate > 0.85)
        badges[member.id] = "🛡️ GUARDIAN";
    }
    return badges;
  }

  String get systemStatus {
    if (hiveStability > 0.8) return "NEURAL STABILITY: OPTIMAL";
    if (hiveStability > 0.45) return "NEURAL STABILITY: DEGRADING";
    return "NEURAL STABILITY: CRITICAL";
  }

  // --- System Methods ---

  /// UPDATED: Added setGlitchState for visual stability feedback
  void setGlitchState(bool active) {
    if (_isSystemGlitching != active) {
      _isSystemGlitching = active;
      if (active) HapticFeedback.heavyImpact();
      notifyListeners();
    }
  }

  /// UPDATED: Restored sendNeuralPing for squad interaction
  void sendNeuralPing(String memberId) {
    _activePingId = memberId;
    HapticFeedback.vibrate();
    sendMessage("NEURAL PING: Contacting node $memberId.", sender: "SYSTEM");
    _addLog(
      "NEURAL PING SENT",
      "Uplink pulse sent to $memberId.",
      Icons.sensors_rounded,
    );

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      _activePingId = null;
      notifyListeners();
    });
  }

  /// UPDATED: Restored setHandler as a primary method for personality changes
  Future<void> setHandler(HandlerPersona newPersona) async {
    _activePersona = newPersona;
    final box = await Hive.openBox('settings');
    await box.put('handler_persona', newPersona.index);

    String logMsg = "";
    switch (newPersona) {
      case HandlerPersona.bestie:
        logMsg = "PERSONALITY: GEN-Z_BESTIE LOADED. NO CAP. 💅";
        break;
      case HandlerPersona.flirt:
        logMsg = "PERSONALITY: ROMANCE_MODULE_ACTIVE. 😉";
        break;
      case HandlerPersona.brutal:
        logMsg = "PERSONALITY: TOXIC_MOTIVATION_ENGAGED. 🖤";
        break;
      case HandlerPersona.system:
        logMsg = "PERSONALITY: DEFAULT_OS_RESTORED. 🤖";
        break;
    }

    sendMessage(logMsg, sender: "SYSTEM");
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  /// Alias for setPersona to support both naming conventions
  Future<void> setPersona(HandlerPersona p) => setHandler(p);

  Future<void> initializeNewHive() async {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String code = List.generate(
      4,
      (i) => chars[random.nextInt(chars.length)],
    ).join();
    _currentHiveId = "HAB-$code-${DateTime.now().year}";

    final box = await Hive.openBox('settings');
    await box.put('hive_id', _currentHiveId);

    _addLog(
      "HIVE INITIALIZED",
      "Protocol ID: $_currentHiveId active.",
      Icons.hub_rounded,
    );
    joinHive(_currentHiveId!);
    notifyListeners();
  }

  void triggerSquadReaction(String habitName, bool isRare) {
    final node = _ghostNodes[Random().nextInt(_ghostNodes.length)];
    String reaction = isRare
        ? "ANOMALY DETECTED! MASSIVE SYNC ON $habitName."
        : "NODE $userName VERIFIED PROTOCOL: $habitName.";

    sendMessage(reaction.toUpperCase(), sender: node['name']!);
    _addLog(
      "SQUAD SYNC",
      "${node['name']} acknowledged $habitName",
      Icons.wifi_protected_setup_rounded,
    );
  }

  // --- Mission Control ---

  void dispatchMission(BuildContext context, String goal) {
    _isMissionActive = true;
    _activeMissionGoal = goal;
    _collectiveMissionProgress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(
          const Duration(seconds: 3),
          () => Navigator.pop(context),
        );
        return MissionLaunchOverlay(goal: goal);
      },
    );
    notifyListeners();
  }

  void updateMissionProgress(BuildContext context, double contribution) {
    if (!_isMissionActive) return;
    _collectiveMissionProgress = (_collectiveMissionProgress + contribution)
        .clamp(0.0, 1.0);

    if (_collectiveMissionProgress >= 1.0) {
      _isMissionActive = false;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          Future.delayed(
            const Duration(seconds: 4),
            () => Navigator.pop(context),
          );
          return const MissionSuccessGlitch();
        },
      );
      sendMessage("MISSION SECURED. REWARDS ENCRYPTED.", sender: "COMMAND");
    }
    notifyListeners();
  }

  // --- Utility & Storage ---

  Future<void> loadHiveSettings() async {
    final box = await Hive.openBox('settings');
    _currentHiveId = box.get('hive_id');
    int? personaIndex = box.get('handler_persona');
    if (personaIndex != null)
      _activePersona = HandlerPersona.values[personaIndex];
    if (_currentHiveId != null) joinHive(_currentHiveId!);
    notifyListeners();
  }

  void joinHive(String hiveId) {
    _currentHiveId = hiveId;
    _members = [
      HiveMember(
        id: "USR-01",
        displayName: userName,
        syncRate: 0.95,
        isOnline: true,
      ),
      ..._ghostNodes.map(
        (node) => HiveMember(
          id: node['id']!,
          displayName: node['name']!,
          syncRate: 0.3 + Random().nextDouble() * 0.5,
          isOnline: true,
        ),
      ),
    ];
    notifyListeners();
  }

  Future<void> copyProtocolToClipboard() async {
    if (_currentHiveId != null) {
      await Clipboard.setData(ClipboardData(text: _currentHiveId!));
      HapticFeedback.mediumImpact();
      sendMessage("PROTOCOL ID COPIED TO CLIPBOARD.", sender: "SYSTEM");
    }
  }

  void sendMessage(String text, {String sender = "COMMAND"}) {
    if (text.isEmpty) return;
    _messages.add({"sender": sender, "text": text});
    if (_messages.length > 50) _messages.removeAt(0);
    notifyListeners();
  }

  void _addLog(String title, String description, IconData icon) {
    _hiveLogs.insert(0, {
      'title': title.toUpperCase(),
      'description': description,
      'icon': icon,
      'timestamp': DateTime.now(),
    });
  }
}
