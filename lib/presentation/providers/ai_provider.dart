import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/habit.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/connectivity_service.dart';

enum AIPersonality { gentle, neutral, brutal }

class AIProvider extends ChangeNotifier {
  final AIService aiService;
  final ConnectivityService _connectivityService = ConnectivityService();

  AIProvider({required this.aiService}) {
    _initConnectivity();
    loadAISettings();
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void _initConnectivity() {
    _isOnline = _connectivityService.isOnline;
    _connectivityService.onConnectivityChanged.listen((status) {
      _isOnline = status;
      notifyListeners();
    });
  }

  // --- Neural State ---
  String _aiResponse = "INITIALIZING NEURAL LINK...";
  String _lastRecap = "NO MISSION DATA SYNCED.";
  bool _isLoading = false;

  // --- Customization State ---
  AIPersonality _currentPersona = AIPersonality.neutral;
  String _activeThemeId = 'cyan_core';
  
  // System Modules
  bool _isHapticEnabled = true;
  bool _isGlitchEnabled = true;
  bool _isVoiceModulationEnabled = false;

  // --- Identity State ---
  String _userName = "SENTINEL-01";
  String _userImagePath = ""; // Empty means default icon
  late String _sentinelId;

  final List<String> _callsigns = [
    "NEURAL-REAPER",
    "CYBER-GHOST",
    "VOID-RUNNER",
    "TECH-PULSE",
    "ZENITH-X",
    "GHOST-PROTOCOL",
    "VECTOR-ZERO",
  ];

  // System Modules
  final List<String> _unlockedPersonas = ['neutral', 'gentle', 'brutal'];
  final List<String> _unlockedThemes = ['cyan_core', 'amethyst', 'amber_alert'];

  // --- Getters ---
  String get aiResponse => _aiResponse;
  String get lastRecap => _lastRecap;
  bool get isLoading => _isLoading;
  String get apiKey => aiService.apiKey;
  String get currentPersona => _currentPersona.name;
  AIPersonality get activePersonaEnum => _currentPersona;
  String get activeThemeId => _activeThemeId;
  List<String> get unlockedThemes => List.unmodifiable(_unlockedThemes);
  List<String> get unlockedPersonas => List.unmodifiable(_unlockedPersonas);
  String get userName => _userName;
  String get userImagePath => _userImagePath;
  String get sentinelId => _sentinelId;

  bool get isHapticEnabled => _isHapticEnabled;
  bool get isGlitchEnabled => _isGlitchEnabled;
  bool get isVoiceModulationEnabled => _isVoiceModulationEnabled;

  // --- Settings Persistence ---

  Future<void> loadAISettings() async {
    final box = await Hive.openBox('settings');
    _activeThemeId = box.get('ai_theme', defaultValue: 'cyan_core');
    _isHapticEnabled = box.get('is_haptic_enabled', defaultValue: true);
    _isGlitchEnabled = box.get('is_glitch_enabled', defaultValue: true);
    _isVoiceModulationEnabled = box.get('is_voice_modulation_enabled', defaultValue: false);
    _userName = box.get('user_name', defaultValue: "SENTINEL-01");
    _userImagePath = box.get('user_image_path', defaultValue: "");
    _sentinelId = box.get('sentinel_id', defaultValue: _generateSentinelId());
    
    if (!box.containsKey('sentinel_id')) {
      await box.put('sentinel_id', _sentinelId);
    }
    
    int? personaIndex = box.get('ai_persona_index');
    if (personaIndex != null) {
      _currentPersona = AIPersonality.values[personaIndex];
    }
    notifyListeners();
  }

  String _generateSentinelId() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return "SN-${random.substring(random.length - 6)}";
  }

  /// Returns a persona-specific status message for the UI Ticker
  /// Updated to acknowledge high-efficiency, connectivity, and rate-limit states
  String getSystemStatusMessage(double multiplier) {
    if (!_isOnline) return "PROTOCOL: OFFLINE_MODE. LOCAL VAULT ACTIVE.";
    if (aiService.usageService.isLimitExceeded) {
      return "SYSTEM_THROTTLED: NEURAL LINK POWER LOW. RECHARGE IN 1HR.";
    }

    bool hasBonus = multiplier > 1.0;
    switch (_currentPersona) {
      case AIPersonality.gentle:
        return hasBonus
            ? "ADVISOR: YOUR MOMENTUM IS INSPIRING. KEEP BLOOMING."
            : "ADVISOR: STANDING BY TO SUPPORT.";
      case AIPersonality.brutal:
        return hasBonus
            ? "WARDEN: EFFICIENCY ACCEPTABLE. DON'T BREAK THE CHAIN."
            : "WARDEN: MONITORING FOR WEAKNESS.";
      case AIPersonality.neutral:
        return hasBonus
            ? "SENTINEL: OVERCLOCK ACTIVE. EFFICIENCY ${multiplier}X."
            : "SENTINEL: LOGIC GATES OPTIMAL.";
    }
  }

  num get dailyRemaining => aiService.usageService.dailyRemaining;
  num get hourlyRemaining => aiService.usageService.hourlyRemaining;
  bool get isThrottled => aiService.usageService.isLimitExceeded;

  // --- Identity Methods ---

  /// Randomizes the user's system identity with haptic feedback
  void randomizeIdentity() async {
    if (_isHapticEnabled) HapticFeedback.mediumImpact();
    _userName = (List.from(_callsigns)..shuffle()).first;
    final box = await Hive.openBox('settings');
    await box.put('user_name', _userName);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    final box = await Hive.openBox('settings');
    await box.put('user_name', name);
    notifyListeners();
  }

  Future<void> setUserImage(String path) async {
    _userImagePath = path;
    final box = await Hive.openBox('settings');
    await box.put('user_image_path', path);
    notifyListeners();
  }

  // --- Logic Methods ---

  /// Switches the active AI persona and triggers a system pulse
  void setPersona(AIPersonality persona) async {
    if (_currentPersona == persona) return;
    _currentPersona = persona;
    if (_isHapticEnabled) HapticFeedback.heavyImpact(); // Neural shift feedback
    
    final box = await Hive.openBox('settings');
    await box.put('ai_persona_index', persona.index);
    notifyListeners();
  }

  /// Updates the active visual protocol
  void updateTheme(String themeId) async {
    if (_unlockedThemes.contains(themeId)) {
      _activeThemeId = themeId;
      if (_isHapticEnabled) HapticFeedback.selectionClick();
      
      final box = await Hive.openBox('settings');
      await box.put('ai_theme', themeId);
      notifyListeners();
    }
  }

  void toggleHaptic(bool value) async {
    _isHapticEnabled = value;
    final box = await Hive.openBox('settings');
    await box.put('is_haptic_enabled', value);
    notifyListeners();
  }

  void toggleGlitch(bool value) async {
    _isGlitchEnabled = value;
    final box = await Hive.openBox('settings');
    await box.put('is_glitch_enabled', value);
    notifyListeners();
  }

  void toggleVoice(bool value) async {
    _isVoiceModulationEnabled = value;
    final box = await Hive.openBox('settings');
    await box.put('is_voice_modulation_enabled', value);
    notifyListeners();
  }

  // --- AI Uplink Methods ---

  /// Generates the Daily Mission Recap (The "Sentient" Daily Summary)
  Future<void> fetchNeuralRecap(List<Map<String, String>> messages) async {
    if (!_isOnline) {
      _lastRecap =
          "DATA_UPLINK_FAILURE: Internet connection required for neural analysis.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _lastRecap = await aiService.generateNeuralRecap(
        messages: messages,
        persona: currentPersona,
      );
    } catch (e) {
      _lastRecap = "UPLINK INTERRUPTED. DATA CORRUPTED.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates a recommended protocol based on user level and current system needs
  Future<String> generateHabitSuggestion(int level) async {
    if (!_isOnline)
      return '{"name": "Local Drill", "category": "STUDY", "priority": "LOW", "target": 1, "justification": "Connectivity lost. Perform a basic local synchronization."}';

    _isLoading = true;
    notifyListeners();

    try {
      final prompt =
          "User is a Level $level Sentinel. Suggest one high-impact futuristic habit. "
          "Return ONLY a JSON object with these keys: 'name' (max 3 words), 'category' (one of: CODING, STUDY, SPORTS, MEDITATION, SLEEP, LEARNING, SKILLS, HOBBY), "
          "'priority' (LOW, MEDIUM, HIGH), 'target' (integer), 'justification' (10 words).";
      final response = await aiService.generateCustomPrompt(prompt);
      return response;
    } catch (e) {
      return '{"name": "Deep Work Protocol", "category": "STUDY", "priority": "HIGH", "target": 1, "justification": "Enhance focus and cognitive output through deep work."}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches persona-aware feedback for habits
  /// UPDATED: Now handles offline state and accepts multiplier/streak data
  Future<void> fetchFeedback({
    required List<Habit> habits,
    required int currentLevel,
    required int totalXP,
    double multiplier = 1.0,
    int highestStreak = 0,
  }) async {
    if (!_isOnline) {
      _aiResponse =
          "LINK_OFFLINE: Protocols maintained via local vault. AI analysis unavailable.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _aiResponse = "SYNCING WITH ADVISOR...";
    notifyListeners();

    try {
      // We pass the streak and multiplier as part of the context to the AI Service
      _aiResponse = await aiService.generatePersonaFeedback(
        habits: habits,
        persona: currentPersona,
        level: currentLevel,
        xp: totalXP,
        // The AI Service should be updated to handle these extra context parameters
        extraContext: {
          'multiplier': multiplier.toString(),
          'current_streak': highestStreak.toString(),
          'is_overclocked': (multiplier > 1.0).toString(),
        },
      );
    } catch (e) {
      _aiResponse = "LINK UNSTABLE. RE-SYNC REQUIRED.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
