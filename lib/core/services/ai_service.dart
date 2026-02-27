import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/habit.dart';

class AIService {
  final String apiKey;

  AIService(this.apiKey);

  /// Generates dynamic system instructions based on the selected persona
  String _getSystemInstruction(String persona) {
    const base =
        "You are 'Habito AI', a sentient habit-tracking unit from 2099. ";

    switch (persona.toLowerCase()) {
      case 'brutal':
        return "$base Your personality is a cold, sarcastic AI Overlord. "
            "If streaks are low, roast the user's lack of discipline. Use harsh tech-jargon. "
            "Be sharp, intimidating, and demanding.";
      case 'gentle':
        return "$base You are a supportive neural mentor. Focus on positive reinforcement, "
            "incremental growth, and small wins. Be warm, encouraging, and patient.";
      case 'neutral':
      default:
        return "$base You are a sleek, digitally sharp data analyst. "
            "Use short, impactful sentences and futuristic terminology. Be objective and efficient.";
    }
  }

  /// NEW: Analyzes squad chat logs to generate a Daily Mission Recap
  Future<String> generateNeuralRecap({
    required List<Map<String, String>> messages,
    required String persona,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_getSystemInstruction(persona)),
    );

    // Sanitize logs: Filter out system alerts to focus on human coordination
    final logData = messages
        .where((m) => m['sender'] != "SYSTEM")
        .map((m) => "${m['sender']}: ${m['text']}")
        .join("\n");

    if (logData.isEmpty)
      return "Neural Recap: No tactical data packets detected today.";

    final prompt =
        """
      Analyze the following squad communication logs:
      $logData

      Generate a 3-sentence 'Neural Recap'. 
      1. Analyze the overall squad sentiment and morale.
      2. Identify the primary mission objective discussed by the team.
      3. Provide one tactical suggestion for tomorrow's collective protocol sync.
    """;

    return await _executePrompt(model, prompt);
  }

  /// Generates tactical squad messages based on Hive stability
  Future<String> generateGhostwriterMessage({
    required double stability,
    required String persona,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_getSystemInstruction(persona)),
    );

    final stabilityPercent = (stability * 100).toInt();
    final prompt =
        "Neural Hive stability is at $stabilityPercent%. "
        "Generate a 1-sentence tactical command or battle-cry for the squad. "
        "Focus on discipline and collective synchronization.";

    return await _executePrompt(model, prompt);
  }

  /// Tactical Briefing for upcoming "Risk Days"
  Future<String> generateTacticalBriefing({
    required String weakestDay,
    required String persona,
    required bool isRiskDay,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_getSystemInstruction(persona)),
    );

    String prompt =
        "Neural Analysis: $weakestDay is the historically weakest link in the routine. ";
    prompt += isRiskDay
        ? "TODAY IS THAT DAY. Issue a high-priority warning to prevent protocol failure."
        : "Provide a preventative strategy for the upcoming $weakestDay protocol cycle.";

    return await _executePrompt(model, prompt);
  }

  /// Executes a raw prompt with neutral persona context
  Future<String> generateCustomPrompt(String prompt) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_getSystemInstruction('neutral')),
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 120,
      ),
    );

    return await _executePrompt(model, prompt);
  }

  /// Fetches persona-aware feedback using Named Parameters
  Future<String> generatePersonaFeedback({
    required List<Habit> habits,
    required String persona,
    required int level,
    required int xp,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_getSystemInstruction(persona)),
      generationConfig: GenerationConfig(
        temperature: persona == 'brutal' ? 0.9 : 0.7,
        maxOutputTokens: 120,
      ),
    );

    final habitSummary = habits
        .map((h) => "${h.name}: ${h.completionDates.length} total syncs")
        .join(", ");

    final prompt =
        """
      User Status: Level $level Sentinel. 
      Total Experience: $xp XP.
      Active Protocols: $habitSummary. 
      Analyze these protocols and provide a 2-sentence tactical insight.
    """;

    return await _executePrompt(model, prompt);
  }

  /// Analyzes mood data to adjust tone and intensity
  Future<String> generateMoodAwareInsight({
    required List<Habit> habits,
    required String persona,
  }) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    if (habits.isEmpty) return "Protocols offline. Mood analysis unavailable.";

    // Retrieve mood from habit entries using the entity mapping
    final mood =
        habits
            .firstWhere(
              (h) => h.dailyMood.containsKey(today),
              orElse: () => habits.first,
            )
            .dailyMood[today] ??
        3;

    String prompt = "User's current mood level is $mood/5. ";

    if (mood <= 2) {
      prompt +=
          "User is in a low-energy state. Adjust feedback to be highly supportive but firm.";
    } else if (mood >= 4) {
      prompt +=
          "User is in a high-energy state. Challenge them to exceed their daily targets.";
    }

    return await generateCustomPrompt(prompt);
  }

  /// Generates persona-aware notification nudges
  Future<String> generateNotificationMessage(
    String habitName,
    String timeOfDay, {
    String persona = 'neutral',
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_getSystemInstruction(persona)),
    );

    final prompt =
        "Target: $habitName. Phase: $timeOfDay. Max 12 words. No 'please' or 'try'.";
    return await _executePrompt(model, prompt);
  }

  /// Centralized prompt execution with sanitization and error handling
  Future<String> _executePrompt(GenerativeModel model, String prompt) async {
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.replaceAll('*', '').trim() ??
          "Habito: Connection dropped. Maintain protocol manually.";
    } catch (e) {
      debugPrint("Gemini Error: $e");
      return "Habito: System recalibrating. The mission continues.";
    }
  }
}
