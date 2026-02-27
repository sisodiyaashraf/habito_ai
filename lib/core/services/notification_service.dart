import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../../presentation/providers/hive_provider.dart';
import 'personality_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Neural Engagement: ${details.id}");
      },
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// --- THE ROTATION ENGINE ---
  static Future<void> schedulePersonaSmartNudges({
    required HandlerPersona persona,
  }) async {
    final library = NeuralPersonaLibrary.getNudges()[persona]!;
    final List<int> hours = [9, 13, 18, 22];

    for (int dayOffset = 0; dayOffset < 4; dayOffset++) {
      final DateTime targetDate = DateTime.now().add(Duration(days: dayOffset));

      for (int i = 0; i < hours.length; i++) {
        int hour = hours[i];
        int messageIndex = (targetDate.day + i) % library.length;
        var selected = library[messageIndex];

        int uniqueId = 9000 + (dayOffset * 10) + i;

        await _notifications.zonedSchedule(
          id: uniqueId, // Explicitly Named
          title: selected['title'],
          body: selected['body'],
          scheduledDate: _nextInstanceOfSpecificDayAndTime(
            targetDate,
            hour,
            0,
          ), // Explicitly Named
          notificationDetails: NotificationDetails(
            // Explicitly Named
            android: AndroidNotificationDetails(
              'persona_nudge',
              'Sentient Nudges',
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound(
                persona == HandlerPersona.brutal
                    ? 'glitch_error'
                    : 'neutral_blip',
              ),
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  /// --- INSTANT FEEDBACK ---
  static Future<void> showInstantPersonaNudge({
    required HandlerPersona persona,
    required String title,
    required String body,
  }) async {
    String channelId = "system_sync";
    String soundAsset = "neutral_blip";

    switch (persona) {
      case HandlerPersona.bestie:
        channelId = "bestie_nudge";
        soundAsset = "bestie_sparkle";
        break;
      case HandlerPersona.flirt:
        channelId = "flirt_nudge";
        soundAsset = "soft_chime";
        break;
      case HandlerPersona.brutal:
        channelId = "brutal_nudge";
        soundAsset = "glitch_error";
        break;
      default:
        channelId = "system_sync";
        soundAsset = "neutral_blip";
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'System Sync',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundAsset),
    );

    await _notifications.show(
      id: DateTime.now().millisecond % 100000, // Explicitly Named
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
      ), // Explicitly Named
    );
  }

  /// --- HABIT REMINDERS ---
  static Future<void> scheduleWeeklyHabitNudge({
    required int id,
    required String title,
    required String body,
    required List<int> scheduledDays,
    required int hour,
    required int minute,
    HandlerPersona persona = HandlerPersona.system,
  }) async {
    await _notifications.cancel(id: id);

    String channelId = "system_sync";
    switch (persona) {
      case HandlerPersona.bestie:
        channelId = "bestie_nudge";
        break;
      case HandlerPersona.flirt:
        channelId = "flirt_nudge";
        break;
      case HandlerPersona.brutal:
        channelId = "brutal_nudge";
        break;
      default:
        channelId = "system_sync";
    }

    for (int day in scheduledDays) {
      final int dailyId = id + day;

      await _notifications.zonedSchedule(
        id: dailyId, // Explicitly Named
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfDayAndTime(
          day,
          hour,
          minute,
        ), // Explicitly Named
        notificationDetails: NotificationDetails(
          // Explicitly Named
          android: AndroidNotificationDetails(
            channelId,
            'Protocol Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // --- Utility Timing Methods ---

  static tz.TZDateTime _nextInstanceOfSpecificDayAndTime(
    DateTime date,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    return scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfDayAndTime(
    int day,
    int hour,
    int minute,
  ) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> cancelNudge(int id) async =>
      await _notifications.cancel(id: id);
  static Future<void> cancelAllNotifications() async =>
      await _notifications.cancelAll();
}
