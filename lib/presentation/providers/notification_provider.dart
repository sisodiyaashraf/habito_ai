import 'package:flutter/material.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/personality_constants.dart';
import '../../domain/entities/habit.dart';
import '../providers/hive_provider.dart'; // Import to access active persona

class NotificationProvider extends ChangeNotifier {
  final AIService aiService;
  final _dndPlugin = DoNotDisturbPlugin();

  NotificationProvider({required this.aiService});

  // --- SYSTEM STATES ---
  bool _isGhostModeEnabled = false;
  bool _isMuteEnabled = false;

  bool get isGhostModeEnabled => _isGhostModeEnabled;
  bool get isMuteEnabled => _isMuteEnabled;

  // --- TOGGLE LOGIC ---

  Future<void> toggleGhostMode(bool value) async {
    _isGhostModeEnabled = value;
    if (_isGhostModeEnabled) {
      bool hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (!hasAccess) {
        await _dndPlugin.openNotificationPolicyAccessSettings();
      }
    }
    notifyListeners();
  }

  void toggleMute(bool value) {
    _isMuteEnabled = value;
    notifyListeners();
  }

  // --- SMART NUDGE LOGIC ---

  /// Recalibrates the schedule using the Rotating Persona Engine
  Future<void> scheduleDailySmartNudges(
    List<Habit> habits,
    HandlerPersona activePersona,
  ) async {
    // 1. Safety Check
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) return;

    // 2. Clear stale nudges
    await NotificationService.cancelAllNotifications();

    if (habits.isEmpty) return;

    // 3. Deploy the Rotating Persona Schedule (The 4-day variety loop)
    // This handles the "Sentient" pokes throughout the day
    await NotificationService.schedulePersonaSmartNudges(
      persona: activePersona,
    );

    // 4. Schedule specific Habit Reminders (Protocol-Specific)
    final now = DateTime.now();
    final incompleteHabits = habits.where((h) {
      bool isDoneToday = h.completionDates.any(
        (d) => d.day == now.day && d.month == now.month && d.year == now.year,
      );
      return !isDoneToday && h.isNotificationsEnabled;
    }).toList();

    for (var habit in incompleteHabits) {
      final parts = habit.reminderTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Schedule the specific time the user set for this habit
      await NotificationService.scheduleWeeklyHabitNudge(
        id: habit.id.hashCode,
        title: "PROTOCOL: ${habit.name.toUpperCase()}",
        body: _getStaticFallback(activePersona, habit.name),
        scheduledDays: habit.scheduledDays,
        hour: hour,
        minute: minute,
        persona: activePersona,
      );
    }

    notifyListeners();
  }

  /// Returns a quick fallback message if AI fails, matching the Persona vibe
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

  /// Clears all scheduled neural nudges
  Future<void> cancelAllNudges() async {
    await NotificationService.cancelAllNotifications();
    notifyListeners();
  }
}
