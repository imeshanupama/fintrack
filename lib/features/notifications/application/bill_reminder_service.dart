import '../domain/notification.dart';
import '../domain/notification_settings.dart';
import '../../recurring/domain/recurring_transaction.dart';
import 'notification_service.dart';
import 'package:uuid/uuid.dart';

class BillReminderService {
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  BillReminderService(this._notificationService);

  Future<void> checkBillReminders({
    required List<RecurringTransaction> recurringTransactions,
    required NotificationSettings settings,
  }) async {
    if (!settings.billRemindersEnabled || !settings.notificationsEnabled) {
      return;
    }

    final now = DateTime.now();
    final daysToCheck = settings.billReminderDaysBefore;

    for (final recurring in recurringTransactions) {
      final nextDueDate = _calculateNextDueDate(recurring);
      if (nextDueDate == null) continue;

      final daysUntilDue = nextDueDate.difference(now).inDays;

      // Send reminder if within the reminder window
      if (daysUntilDue >= 0 && daysUntilDue <= daysToCheck) {
        await _sendBillReminder(recurring, nextDueDate, daysUntilDue);
      }
    }
  }

  DateTime? _calculateNextDueDate(RecurringTransaction recurring) {
    final now = DateTime.now();
    DateTime nextDate = recurring.startDate;

    // Calculate next occurrence based on frequency
    while (nextDate.isBefore(now)) {
      switch (recurring.frequency) {
        case 'daily':
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case 'yearly':
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
        default:
          return null;
      }

      // Check if we've passed the end date
      if (recurring.endDate != null && nextDate.isAfter(recurring.endDate!)) {
        return null;
      }
    }

    return nextDate;
  }

  Future<void> _sendBillReminder(
    RecurringTransaction recurring,
    DateTime dueDate,
    int daysUntilDue,
  ) async {
    String title;
    String body;

    if (daysUntilDue == 0) {
      title = '💰 Bill Due Today: ${recurring.description}';
      body = '\$${recurring.amount.toStringAsFixed(2)} is due today';
    } else if (daysUntilDue == 1) {
      title = '💰 Bill Due Tomorrow: ${recurring.description}';
      body = '\$${recurring.amount.toStringAsFixed(2)} is due tomorrow';
    } else {
      title = '💰 Bill Due Soon: ${recurring.description}';
      body = '\$${recurring.amount.toStringAsFixed(2)} due in $daysUntilDue days';
    }

    final notification = AppNotification(
      id: _uuid.v4(),
      type: NotificationType.bill,
      priority: daysUntilDue == 0 ? NotificationPriority.urgent : NotificationPriority.high,
      title: title,
      body: body,
      data: {
        'recurringId': recurring.id,
        'dueDate': dueDate.toIso8601String(),
        'amount': recurring.amount,
      },
      scheduledTime: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }
}
