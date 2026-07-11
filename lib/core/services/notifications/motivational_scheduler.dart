import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../personality_constants.dart';
import 'notification_service.dart';
import 'notification_utils.dart';

class MotivationalScheduler {
  /// Schedules motivational quotes daily 3 times a day (08:00, 14:00, 20:00)
  static Future<void> scheduleDailyMotivation() async {
    final library = NeuralPersonaLibrary.getNudges()[HandlerPersona.motivational]!;
    final List<int> hours = [8, 14, 20]; // 3 times a day as requested

    final now = DateTime.now();

    for (int i = 0; i < hours.length; i++) {
      int hour = hours[i];
      
      int messageIndex = (now.day + i) % library.length;
      var selected = library[messageIndex];
      
      // Use a strictly unique ID for each slot: 20000 + i
      int uniqueId = 20000 + i;

      await NotificationService.instance.zonedSchedule(
        id: uniqueId,
        title: "NEURAL BOOST",
        body: selected['body'],
        scheduledDate: NotificationUtils.nextInstanceOfTime(
          hour,
          0,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'motivational_nudge',
            'Daily Motivation',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('soft_chime'),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
