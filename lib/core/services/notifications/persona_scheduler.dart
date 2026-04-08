import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../personality_constants.dart';
import 'notification_service.dart';
import 'notification_utils.dart';

class PersonaScheduler {
  /// Schedules the 4-stage daily cycle
  static Future<void> schedulePersonaSmartNudges({
    required HandlerPersona persona,
  }) async {
    final library = NeuralPersonaLibrary.getNudges()[persona]!;
    final List<int> hours = [9, 13, 18, 22];

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final DateTime targetDate = DateTime.now().add(Duration(days: dayOffset));

      for (int i = 0; i < hours.length; i++) {
        int hour = hours[i];
        int messageIndex = (targetDate.day + i) % library.length;
        var selected = library[messageIndex];
        int uniqueId = 9000 + (dayOffset * 10) + i;

        // FIX: Explicitly naming 'id', 'scheduledDate', and 'notificationDetails'
        await NotificationService.instance.zonedSchedule(
          id: uniqueId,
          title: selected['title'],
          body: selected['body'],
          scheduledDate: NotificationUtils.nextInstanceOfSpecificDayAndTime(
            targetDate,
            hour,
            0,
          ),
          notificationDetails: NotificationDetails(
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

  static Future<void> showInstantPersonaNudge({
    required HandlerPersona persona,
    required String title,
    required String body,
  }) async {
    String soundAsset = persona == HandlerPersona.brutal
        ? 'glitch_error'
        : 'neutral_blip';

    // FIX: Explicitly naming 'id' and 'notificationDetails'
    await NotificationService.instance.show(
      id: DateTime.now().millisecond % 100000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'system_sync',
          'System Sync',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundAsset),
        ),
      ),
    );
  }
}
