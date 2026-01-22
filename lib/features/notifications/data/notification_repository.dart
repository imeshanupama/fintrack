import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../domain/notification.dart';
import '../domain/notification_settings.dart';

class NotificationRepository {
  late Box _notificationsBox;
  late Box _settingsBox;

  NotificationRepository() {
    _notificationsBox = Hive.box(BoxNames.notificationsBox);
    _settingsBox = Hive.box(BoxNames.settings);
  }

  // Settings
  NotificationSettings getSettings() {
    final json = _settingsBox.get('notification_settings');
    if (json == null) return NotificationSettings();
    return NotificationSettings.fromJson(Map<String, dynamic>.from(json));
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    await _settingsBox.put('notification_settings', settings.toJson());
  }

  // Notifications
  List<AppNotification> getNotifications() {
    final notifications = _notificationsBox.values
        .map((json) => AppNotification.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    
    // Sort by scheduled time, newest first
    notifications.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    return notifications;
  }

  Future<void> saveNotification(AppNotification notification) async {
    await _notificationsBox.put(notification.id, notification.toJson());
  }

  Future<void> markAsRead(String id) async {
    final json = _notificationsBox.get(id);
    if (json != null) {
      final notification = AppNotification.fromJson(Map<String, dynamic>.from(json));
      final updated = notification.copyWith(isRead: true, readAt: DateTime.now());
      await _notificationsBox.put(id, updated.toJson());
    }
  }

  Future<void> deleteNotification(String id) async {
    await _notificationsBox.delete(id);
  }

  Future<void> clearAll() async {
    await _notificationsBox.clear();
  }

  List<AppNotification> getUnreadNotifications() {
    return getNotifications().where((n) => !n.isRead).toList();
  }

  int getUnreadCount() {
    return getUnreadNotifications().length;
  }
}
