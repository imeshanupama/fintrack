import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification.dart';
import '../domain/notification_settings.dart';
import '../application/notification_service.dart';
import '../application/budget_alert_service.dart';
import '../application/bill_reminder_service.dart';
import '../application/anomaly_detector_service.dart';
import '../data/notification_repository.dart';

// Service providers
final notificationServiceProvider = Provider((ref) => NotificationService());
final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

// Alert service providers
final budgetAlertServiceProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return BudgetAlertService(notificationService);
});

final billReminderServiceProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return BillReminderService(notificationService);
});

final anomalyDetectorServiceProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return AnomalyDetectorService(notificationService);
});

// Notification settings provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier(ref.read(notificationRepositoryProvider));
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final NotificationRepository _repository;

  NotificationSettingsNotifier(this._repository) : super(_repository.getSettings());

  Future<void> updateSettings(NotificationSettings settings) async {
    await _repository.saveSettings(settings);
    state = settings;
  }

  Future<void> toggleNotifications(bool enabled) async {
    final newSettings = state.copyWith(notificationsEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleBudgetAlerts(bool enabled) async {
    final newSettings = state.copyWith(budgetAlertsEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setBudgetThreshold(int threshold) async {
    final newSettings = state.copyWith(budgetAlertThreshold: threshold);
    await updateSettings(newSettings);
  }

  Future<void> toggleBillReminders(bool enabled) async {
    final newSettings = state.copyWith(billRemindersEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleAnomalyAlerts(bool enabled) async {
    final newSettings = state.copyWith(anomalyAlertsEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleWeeklySummary(bool enabled) async {
    final newSettings = state.copyWith(weeklySummaryEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleMonthlySummary(bool enabled) async {
    final newSettings = state.copyWith(monthlySummaryEnabled: enabled);
    await updateSettings(newSettings);
  }
}

// Notification history provider
final notificationHistoryProvider = StateNotifierProvider<NotificationHistoryNotifier, List<AppNotification>>((ref) {
  return NotificationHistoryNotifier(ref.read(notificationRepositoryProvider));
});

class NotificationHistoryNotifier extends StateNotifier<List<AppNotification>> {
  final NotificationRepository _repository;

  NotificationHistoryNotifier(this._repository) : super(_repository.getNotifications());

  Future<void> addNotification(AppNotification notification) async {
    await _repository.saveNotification(notification);
    state = _repository.getNotifications();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    state = _repository.getNotifications();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    state = [];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}
