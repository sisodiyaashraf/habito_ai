import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/ai_service.dart';
// Updated Imports to match your 4-file architecture
import '../../core/services/notifications/notification_service.dart';
import '../../core/services/notifications/persona_scheduler.dart';
import '../../core/services/notifications/habit_scheduler.dart';
import '../../core/services/personality_constants.dart';
import '../../domain/entities/habit.dart';

class NotificationProvider extends ChangeNotifier {
  final AIService aiService;

  NotificationProvider({required this.aiService});

  // --- SYSTEM STATES ---
  bool _isGhostModeEnabled = false;
  bool _isMuteEnabled = false;

  bool get isGhostModeEnabled => _isGhostModeEnabled;
  bool get isMuteEnabled => _isMuteEnabled;

  // --- TOGGLE LOGIC ---

  Future<void> toggleGhostMode(bool value) async {
    _isGhostModeEnabled = value;
    // Note: DND logic remains the same, ensure do_not_disturb is in pubspec
    notifyListeners();
  }

  void toggleMute(bool value) {
    _isMuteEnabled = value;
    notifyListeners();
  }

  // --- SMART NUDGE LOGIC ---

  /// Recalibrates the schedule using the specialized Schedulers
  Future<void> scheduleDailySmartNudges(
    List<Habit> habits,
    HandlerPersona activePersona,
  ) async {
    // 1. Safety Check: Verify permissions before touching the alarm manager
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) return;

    // 2. Clear stale neural paths
    await NotificationService.cancelAllNotifications();

    if (habits.isEmpty) return;

    // 3. Deploy the 4x Daily Persona Nudges via the PersonaScheduler
    // This handles the "Sentient" pokes independent of specific habits
    await PersonaScheduler.schedulePersonaSmartNudges(persona: activePersona);

    // 4. Schedule specific Habit Reminders via the HabitScheduler
    final now = DateTime.now();

    final incompleteHabits = habits.where((h) {
      // Improved date comparison for real-device precision
      bool isDoneToday = h.completionDates.any(
        (d) => d.year == now.year && d.month == now.month && d.day == now.day,
      );
      return !isDoneToday && h.isNotificationsEnabled;
    }).toList();

    for (var habit in incompleteHabits) {
      try {
        final parts = habit.reminderTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // Hand off to the dedicated HabitScheduler
        await HabitScheduler.scheduleWeeklyHabitNudge(
          id: habit.id.hashCode, // Ensure this is a unique integer
          title: "PROTOCOL: ${habit.name.toUpperCase()}",
          body: _getStaticFallback(activePersona, habit.name),
          scheduledDays: habit.scheduledDays,
          hour: hour,
          minute: minute,
          persona: activePersona,
        );
      } catch (e) {
        debugPrint(
          "Neural Link Error: Failed to schedule nudge for ${habit.name}: $e",
        );
      }
    }

    notifyListeners();
  }

  /// Returns a quick fallback message matching the Persona vibe
  String _getStaticFallback(HandlerPersona persona, String habitName) {
    switch (persona) {
      case HandlerPersona.bestie:
        return "Bestie, $habitName is waiting. Don't let the streak flop! ✨";
      case HandlerPersona.flirt:
        return "I was thinking about you... and your $habitName protocol. Sync up? 😉";
      case HandlerPersona.brutal:
        return "Your $habitName is incomplete. Stop being weak and finish it.";
      case HandlerPersona.system:
      default:
        return "Commander, protocol '$habitName' requires immediate synchronization.";
    }
  }

  /// Clears all scheduled neural nudges via core service
  Future<void> cancelAllNudges() async {
    await NotificationService.cancelAllNotifications();
    notifyListeners();
  }
}
