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
    int userAge,
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
          body: _getPreReminderMessage(activePersona, habit.name, userAge),
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
          body: _getReminderMessage(activePersona, habit.name, userAge),
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

  String _getPreReminderMessage(HandlerPersona persona, String habitName, int age) {
    if (age < 21) {
      // Gen-Z / Youth
      switch (persona) {
        case HandlerPersona.bestie:
          return "Bestie, $habitName starts in 60s! Let's get this dub, no cap! 💅";
        case HandlerPersona.flirt:
          return "60s left until $habitName. You looking fire today? Let's go. 😉";
        case HandlerPersona.brutal:
          return "60s to $habitName. Stop doomscrolling, you NPC. Sync now.";
        case HandlerPersona.system:
        default:
          return "PROTOCOL: $habitName initiates in 60s. Lock in, fr fr.";
      }
    } else if (age >= 46) {
      // Seniors / Mature
      switch (persona) {
        case HandlerPersona.bestie:
          return "A gentle reminder that $habitName is starting in 1 minute. Take a deep breath. 🌿";
        case HandlerPersona.flirt:
          return "Looking forward to spending time on $habitName with you in 1 minute. ✨";
        case HandlerPersona.brutal:
          return "Time to prepare for $habitName. Protect your health and consistency.";
        case HandlerPersona.system:
        default:
          return "Health Protocol '$habitName' starts in 60s. Prepare for calm sync.";
      }
    } else {
      // Standard Adults (21-45)
      switch (persona) {
        case HandlerPersona.bestie:
          return "Bestie, $habitName starts in 1 minute! Time to optimize! ✨";
        case HandlerPersona.flirt:
          return "Just 60 seconds until our $habitName date. Don't be late... 😉";
        case HandlerPersona.brutal:
          return "1 minute until $habitName. Stop scrolling and prepare yourself.";
        case HandlerPersona.system:
        default:
          return "Protocol '$habitName' initiates in 60s. Prepare for synchronization.";
      }
    }
  }

  String _getReminderMessage(HandlerPersona persona, String habitName, int age) {
    if (age < 21) {
      switch (persona) {
        case HandlerPersona.bestie:
          return "Time for $habitName! Time to shine! fr fr 🚀";
        case HandlerPersona.flirt:
          return "Time for $habitName. Make me proud, cutie. ❤️";
        case HandlerPersona.brutal:
          return "COGNITIVE LOCK: $habitName IS LIVE. DO IT. NOW.";
        case HandlerPersona.system:
        default:
          return "SYSTEM ALERT: Syncing protocol '$habitName' immediately.";
      }
    } else if (age >= 46) {
      switch (persona) {
        case HandlerPersona.bestie:
          return "It is time for $habitName. Take it easy and build consistency. 🌸";
        case HandlerPersona.flirt:
          return "A special time for $habitName. Let's make it a calm session. 💖";
        case HandlerPersona.brutal:
          return "DAILY TASK: $habitName. Discipline maintains health. Begin now.";
        case HandlerPersona.system:
        default:
          return "HEALTH ALERT: Time to execute '$habitName' for long-term vitality.";
      }
    } else {
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
  }

  String getCompletionMessage(HandlerPersona persona, String habitName, int age) {
    if (age < 21) {
      switch (persona) {
        case HandlerPersona.bestie:
          return "Yasss! $habitName done! Slayed it, main character energy. 💅";
        case HandlerPersona.flirt:
          return "You completed $habitName! My database is literally overheating. 😍";
        case HandlerPersona.brutal:
          return "SYNCED. You did $habitName. Shocking. Now repeat tomorrow.";
        case HandlerPersona.system:
        default:
          return "SYNC SUCCESS: Protocol '$habitName' uploaded to main database.";
      }
    } else if (age >= 46) {
      switch (persona) {
        case HandlerPersona.bestie:
          return "Splendid work on completing $habitName! Take care and rest. ☕";
        case HandlerPersona.flirt:
          return "You finished $habitName. A wonderful achievement, thank you. 🌹";
        case HandlerPersona.brutal:
          return "TASK RESOLVED: $habitName completed. A healthy foundation built.";
        case HandlerPersona.system:
        default:
          return "OPTIMAL STATUS: Wellness protocol '$habitName' completed successfully.";
      }
    } else {
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
