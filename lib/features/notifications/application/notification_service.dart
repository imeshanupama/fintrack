import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return false;
  }

  Future<void> showNotification(AppNotification notification) async {
    final details = _getNotificationDetails(notification.priority);
    
    await _notifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: notification.id,
    );
  }

  Future<void> scheduleNotification(AppNotification notification) async {
    final details = _getNotificationDetails(notification.priority);
    
    await _notifications.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      tz.TZDateTime.from(notification.scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: notification.id,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  NotificationDetails _getNotificationDetails(NotificationPriority priority) {
    final importance = _getImportance(priority);
    final androidPriority = _getAndroidPriority(priority);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _getChannelId(priority),
        _getChannelName(priority),
        channelDescription: _getChannelDescription(priority),
        importance: importance,
        priority: androidPriority,
        showWhen: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  String _getChannelId(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'urgent_channel';
      case NotificationPriority.high:
        return 'high_channel';
      case NotificationPriority.medium:
        return 'medium_channel';
      case NotificationPriority.low:
        return 'low_channel';
    }
  }

  String _getChannelName(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'Urgent Alerts';
      case NotificationPriority.high:
        return 'Important Notifications';
      case NotificationPriority.medium:
        return 'General Notifications';
      case NotificationPriority.low:
        return 'Low Priority';
    }
  }

  String _getChannelDescription(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'Critical financial alerts requiring immediate attention';
      case NotificationPriority.high:
        return 'Important financial notifications';
      case NotificationPriority.medium:
        return 'General financial updates';
      case NotificationPriority.low:
        return 'Low priority notifications';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // This will be implemented when we add navigation
    print('Notification tapped: ${response.payload}');
  }
}
