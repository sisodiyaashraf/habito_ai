import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

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

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  static void _configureLocalTimeZone() {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      }
    } catch (_) {}

    final Duration offset = DateTime.now().timeZoneOffset;
    for (var location in tz.timeZoneDatabase.locations.values) {
      if (location.zones.any((zone) => zone.offset == offset.inMilliseconds)) {
        tz.setLocalLocation(location);
        return;
      }
    }
  }

  // Getter for the plugin instance to be used by other files in this folder
  static FlutterLocalNotificationsPlugin get instance => _notifications;

  /// Schedules a 'Tactical Alert' with a glitch effect description
  static Future<void> scheduleTacticalAlert({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: "TACTICAL_ALERT: $title",
      body: "SYS_MSG: $body",
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tactical_alerts',
          'Tactical Alerts',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelNudge(int id) async =>
      await _notifications.cancel(id: id);
  static Future<void> cancelAllNotifications() async =>
      await _notifications.cancelAll();
}
