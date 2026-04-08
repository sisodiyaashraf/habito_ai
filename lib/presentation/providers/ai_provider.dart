import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/habit.dart';
import '../../core/services/ai_service.dart';

enum AIPersonality { gentle, neutral, brutal }

class AIProvider extends ChangeNotifier {
  final AIService aiService;

  AIProvider({required this.aiService});

  // --- Neural State ---
  String _aiResponse = "INITIALIZING NEURAL LINK...";
  String _lastRecap = "NO MISSION DATA SYNCED.";
  bool _isLoading = false;

  // --- Customization State ---
  AIPersonality _currentPersona = AIPersonality.neutral;
  String _activeThemeId = 'cyan_core';

  // --- Identity State ---
  String _userName = "SENTINEL-01";
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

  /// Returns a persona-specific status message for the UI Ticker
  /// Updated to acknowledge high-efficiency states
  String getSystemStatusMessage(double multiplier) {
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
      default:
        return hasBonus
            ? "SENTINEL: OVERCLOCK ACTIVE. EFFICIENCY ${multiplier}X."
            : "SENTINEL: LOGIC GATES OPTIMAL.";
    }
  }

  // --- Identity Methods ---

  /// Randomizes the user's system identity with haptic feedback
  void randomizeIdentity() {
    HapticFeedback.mediumImpact();
    _userName = (List.from(_callsigns)..shuffle()).first;
    notifyListeners();
  }

  // --- Logic Methods ---

  /// Switches the active AI persona and triggers a system pulse
  void setPersona(AIPersonality persona) {
    if (_currentPersona == persona) return;
    _currentPersona = persona;
    HapticFeedback.heavyImpact(); // Neural shift feedback
    notifyListeners();
  }

  /// Updates the active visual protocol
  void updateTheme(String themeId) {
    if (_unlockedThemes.contains(themeId)) {
      _activeThemeId = themeId;
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  // --- AI Uplink Methods ---

  /// Generates the Daily Mission Recap (The "Sentient" Daily Summary)
  Future<void> fetchNeuralRecap(List<Map<String, String>> messages) async {
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
    _isLoading = true;
    notifyListeners();

    try {
      final prompt =
          "User is a Level $level Sentinel. Suggest one high-impact futuristic habit name (max 3 words) and a brief 10-word justification.";
      final response = await aiService.generateCustomPrompt(prompt);
      return response;
    } catch (e) {
      return "RECONNAISSANCE_FAILED: Suggest 'Deep Work Protocol'.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches persona-aware feedback for habits
  /// UPDATED: Now accepts multiplier and streak data to provide targeted AI coaching
  Future<void> fetchFeedback({
    required List<Habit> habits,
    required int currentLevel,
    required int totalXP,
    double multiplier = 1.0,
    int highestStreak = 0,
  }) async {
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
