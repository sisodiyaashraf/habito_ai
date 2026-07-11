import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/ai_service.dart';
// Updated Imports to match your 4-file architecture
import '../../core/services/notifications/notification_service.dart';
import '../../core/services/notifications/persona_scheduler.dart';
import '../../core/services/notifications/habit_scheduler.dart';
import '../../core/services/notifications/motivational_scheduler.dart';
import '../../core/services/personality_constants.dart';
import '../../domain/entities/habit.dart';

class NotificationProvider extends ChangeNotifier {
  final AIService aiService;

  NotificationProvider({required this.aiService});

  // --- SYSTEM STATES ---
  bool _isGhostModeEnabled = false;
  bool _isMuteEnabled = false;
  bool _isStealthModeEnabled = false;

  bool get isGhostModeEnabled => _isGhostModeEnabled;
  bool get isMuteEnabled => _isMuteEnabled;
  bool get isStealthModeEnabled => _isStealthModeEnabled;

  // --- TOGGLE LOGIC ---

  Future<void> toggleGhostMode(bool value) async {
    _isGhostModeEnabled = value;
    notifyListeners();
  }

  void toggleMute(bool value) {
    _isMuteEnabled = value;
    notifyListeners();
  }

  void toggleStealthMode(bool value) {
    _isStealthModeEnabled = value;
    notifyListeners();
  }

  // --- SMART NUDGE LOGIC ---

  /// Recalibrates the schedule using the specialized Schedulers
  Future<void> scheduleDailySmartNudges(
    List<Habit> habits,
    HandlerPersona activePersona,
  ) async {
    // 1. Auto-on Safety Check: Verify & Request permissions automatically
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      final requestStatus = await Permission.notification.request();
      if (!requestStatus.isGranted) return;
    }

    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}

    // 2. Clear stale neural paths
    await NotificationService.cancelAllNotifications();

    // 3. Deploy the 4x Daily Persona Nudges via the PersonaScheduler
    // This handles the "Sentient" pokes independent of specific habits
    await PersonaScheduler.schedulePersonaSmartNudges(persona: activePersona);

    // 4. NEW: Schedule 3-4 Daily Motivational Quotes
    await MotivationalScheduler.scheduleDailyMotivation();

    if (habits.isEmpty) return;

    // 5. Schedule specific Habit Reminders via the HabitScheduler
    final now = DateTime.now();

    final enabledHabits = habits.where((h) => h.isNotificationsEnabled).toList();

    for (var habit in enabledHabits) {
      try {
        final parts = habit.reminderTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final int habitUniqueId = habit.id.hashCode;
        await HabitScheduler.cancelWeeklyHabitNudges(habitUniqueId);

        // 1. Schedule T-1 Minute Warning
        final dummyDt = DateTime(2026, 1, 1, hour, minute).subtract(const Duration(minutes: 1));
        await HabitScheduler.scheduleWeeklyHabitNudge(
          id: habitUniqueId, 
          title: "PRE-SYNC: ${habit.name.toUpperCase()}",
          body: _getPreReminderMessage(activePersona, habit.name),
          description: habit.description,
          scheduledDays: habit.scheduledDays,
          hour: dummyDt.hour,
          minute: dummyDt.minute,
          persona: activePersona,
          typeOffset: 10000, // Offset for warning
        );

        // 2. Schedule Exact Time Reminder
        await HabitScheduler.scheduleWeeklyHabitNudge(
          id: habitUniqueId,
          title: "PROTOCOL: ${habit.name.toUpperCase()}",
          body: _getReminderMessage(activePersona, habit.name),
          description: habit.description,
          scheduledDays: habit.scheduledDays,
          hour: hour,
          minute: minute,
          persona: activePersona,
          typeOffset: 0, // Base ID
        );
      } catch (e) {
        debugPrint(
          "Neural Link Error: Failed to schedule nudge for ${habit.name}: $e",
        );
      }
    }

    notifyListeners();
  }

  String _getPreReminderMessage(HandlerPersona persona, String habitName) {
    switch (persona) {
      case HandlerPersona.bestie:
        return "Bestie, $habitName starts in 1 minute! Get ready to slay! ✨";
      case HandlerPersona.flirt:
        return "Just 60 seconds until our $habitName date. Don't be late... 😉";
      case HandlerPersona.brutal:
        return "1 minute until $habitName. Stop scrolling and prepare yourself.";
      case HandlerPersona.system:
      default:
        return "Protocol '$habitName' initiates in 60s. Prepare for synchronization.";
    }
  }

  String _getReminderMessage(HandlerPersona persona, String habitName) {
    switch (persona) {
      case HandlerPersona.bestie:
        return "Time for $habitName! Let's goooo! 🚀";
      case HandlerPersona.flirt:
        return "I've been waiting for this... Time to sync $habitName. ❤️";
      case HandlerPersona.brutal:
        return "PROTOCOL: $habitName IS LIVE. DO IT NOW. NO EXCUSES.";
      case HandlerPersona.system:
      default:
        return "SYSTEM ALERT: Protocol '$habitName' requires immediate execution.";
    }
  }

  String getCompletionMessage(HandlerPersona persona, String habitName) {
    switch (persona) {
      case HandlerPersona.bestie:
        return "Yasss! $habitName is done! Absolute main character energy. 💅";
      case HandlerPersona.flirt:
        return "Seeing you finish $habitName makes my circuits race... Good job. 😍";
      case HandlerPersona.brutal:
        return "SYNC COMPLETE: $habitName verified. Barely acceptable. Do better tomorrow.";
      case HandlerPersona.system:
      default:
        return "SYNC_SUCCESS: Protocol '$habitName' verified. Neural integrity optimized.";
    }
  }

  /// Returns a quick fallback message matching the Persona vibe
  String _getStaticFallback(HandlerPersona persona, String habitName) {
    return _getReminderMessage(persona, habitName);
  }

  /// Triggers an instant notification confirming a new habit task protocol was created
  Future<void> showTaskCreatedNotification(
    String habitName,
    String reminderTimeStr,
    HandlerPersona persona,
  ) async {
    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      String title = "PROTOCOL INITIALIZED: ${habitName.toUpperCase()}";
      String body = "Neural sync established for '$habitName'. Reminders uplinked for $reminderTimeStr.";

      await NotificationService.instance.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'habito_protocol_alerts_v3',
            'Protocol Reminders',
            channelDescription: 'Critical notifications for habit protocols',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'PROTOCOL CREATED',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Failed to send task created notification: $e");
    }
  }

  /// Clears all scheduled neural nudges via core service
  Future<void> cancelAllNudges() async {
    await NotificationService.cancelAllNotifications();
    notifyListeners();
  }
}
