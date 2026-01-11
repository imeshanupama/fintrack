import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notifications = fln.FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezone
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      debugPrint("Timezone not found, defaulting to UTC: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Initialize Plugin
    const fln.AndroidInitializationSettings androidSettings =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const fln.DarwinInitializationSettings iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const fln.InitializationSettings initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
         debugPrint("Notification tapped: ${response.payload}");
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await _notifications.cancel(0); // Cancel previous

    await _notifications.zonedSchedule(
      0,
      'Daily Reminder',
      'Don\'t forget to log your expenses for today!',
      _nextInstanceOfTime(hour, minute),
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Reminds you to log expenses daily',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: fln.DarwinNotificationDetails(),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time,
    );
    debugPrint("Scheduled daily reminder for $hour:$minute");
  }

  Future<void> cancelReminder() async {
    await _notifications.cancel(0);
    debugPrint("Cancelled daily reminder");
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
