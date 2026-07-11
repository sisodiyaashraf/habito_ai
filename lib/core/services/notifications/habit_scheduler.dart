import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../personality_constants.dart';
import 'notification_service.dart';
import 'notification_utils.dart';

class HabitScheduler {
  static Future<void> cancelWeeklyHabitNudges(int id) async {
    final int hash = id.abs() % 1000;
    for (int day = 1; day <= 7; day++) {
      for (int typeOffset in [0, 10000, 20000]) {
        final int dailyId = 50000 + typeOffset + hash * 10 + day;
        await NotificationService.instance.cancel(id: dailyId);
      }
    }
  }

  static Future<void> scheduleWeeklyHabitNudge({
    required int id,
    required String title,
    required String body,
    String? description,
    required List<int> scheduledDays,
    required int hour,
    required int minute,
    HandlerPersona persona = HandlerPersona.system,
    int typeOffset = 0,
  }) async {
    const String channelId = "habito_protocol_alerts_v3";
    const String channelName = "Protocol Reminders";
    const String channelDesc = "Critical notifications for habit protocols";

    final String fullBody = description != null && description.isNotEmpty 
        ? "$body\nMission: $description" 
        : body;

    final androidDetails = const AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'TACTICAL ALERT',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    for (int day in scheduledDays) {
      final int dailyId = 50000 + typeOffset + (id.abs() % 1000) * 10 + day;
      final int directId = 50000 + typeOffset + 20000 + (id.abs() % 1000) * 10 + day;

      await NotificationService.instance.cancel(id: dailyId);
      await NotificationService.instance.cancel(id: directId);

      final scheduledDate = NotificationUtils.nextInstanceOfDayAndTime(
        day,
        hour,
        minute,
      );

      // 1. Direct one-shot exact alarm for nearest upcoming trigger (bypasses Android Doze mode)
      try {
        await NotificationService.instance.zonedSchedule(
          id: directId,
          title: title,
          body: fullBody,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        try {
          await NotificationService.instance.zonedSchedule(
            id: directId,
            title: title,
            body: fullBody,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (_) {}
      }

      // 2. Weekly recurring alarm schedule
      try {
        await NotificationService.instance.zonedSchedule(
          id: dailyId,
          title: title,
          body: fullBody,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (_) {
        try {
          await NotificationService.instance.zonedSchedule(
            id: dailyId,
            title: title,
            body: fullBody,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } catch (_) {}
      }
    }
  }
}
