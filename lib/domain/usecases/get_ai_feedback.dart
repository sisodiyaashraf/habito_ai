import '../entities/habit.dart';
import '../../core/services/ai_service.dart';

class GetAIFeedback {
  final AIService aiService;

  GetAIFeedback(this.aiService);

  /// Executes the AI insight protocol with gamified context and persona archetypes
  Future<String> execute({
    required List<Habit> habits,
    required String persona,
    required int currentLevel,
    required int totalXP,
  }) async {
    // 1. Edge Case: Handle empty habit protocols
    if (habits.isEmpty) {
      return "Neural Link established. No active protocols detected. Initialize a habit to begin analysis.";
    }

    // 2. Data Aggregation: Use the gamified persona-aware method
    try {
      return await aiService.generatePersonaFeedback(
        habits: habits,
        persona: persona,
        level: currentLevel,
        xp: totalXP,
      );
    } catch (e) {
      // 3. Fallback logic: Construct a tactical prompt including gamification stats
      final habitStats = habits
          .map((h) => "${h.name}: ${h.totalCompletions} completions")
          .join(", ");

      final prompt =
          """
        System Rank: Sentinel (Level $currentLevel). 
        Total Sync XP: $totalXP.
        Persona: $persona. 
        Habit Stats: $habitStats. 
        Analyze neural progress and provide a tactical insight under 25 words.
      """;

      return await aiService.generateCustomPrompt(prompt);
    }
  }
}
