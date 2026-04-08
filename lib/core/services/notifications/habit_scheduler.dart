import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../personality_constants.dart';
import 'notification_service.dart';
import 'notification_utils.dart';

class HabitScheduler {
  static Future<void> scheduleWeeklyHabitNudge({
    required int id,
    required String title,
    required String body,
    required List<int> scheduledDays,
    required int hour,
    required int minute,
    HandlerPersona persona = HandlerPersona.system,
  }) async {
    // FIX: Added the 'id:' parameter name
    await NotificationService.instance.cancel(id: id);

    String channelId = persona == HandlerPersona.brutal
        ? "brutal_nudge"
        : "system_sync";

    for (int day in scheduledDays) {
      final int dailyId = id + day;

      // FIX: Added 'id:', 'scheduledDate:', and 'notificationDetails:' parameter names
      await NotificationService.instance.zonedSchedule(
        id: dailyId,
        title: title,
        body: body,
        scheduledDate: NotificationUtils.nextInstanceOfDayAndTime(
          day,
          hour,
          minute,
        ),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Protocol Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
}
