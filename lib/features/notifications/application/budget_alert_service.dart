import '../domain/notification.dart';
import '../domain/notification_settings.dart';
import '../../budget/domain/budget.dart';
import '../../transactions/domain/transaction.dart';
import 'notification_service.dart';
import 'package:uuid/uuid.dart';

class BudgetAlertService {
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  BudgetAlertService(this._notificationService);

  Future<void> checkBudgets({
    required List<Budget> budgets,
    required List<Transaction> transactions,
    required NotificationSettings settings,
  }) async {
    if (!settings.budgetAlertsEnabled || !settings.notificationsEnabled) {
      return;
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    for (final budget in budgets) {
      // Calculate spending for this budget
      final spending = transactions
          .where((t) =>
              t.categoryId == budget.categoryId &&
              t.type.name == 'expense' &&
              t.date.isAfter(startOfMonth))
          .fold(0.0, (sum, t) => sum + t.amount);

      final percentage = (spending / budget.amount) * 100;

      // Check if we should send an alert
      if (percentage >= 100 && percentage < 120) {
        await _sendBudgetExceededAlert(budget, spending, percentage);
      } else if (percentage >= settings.budgetAlertThreshold && percentage < 100) {
        await _sendBudgetThresholdAlert(budget, spending, percentage, settings.budgetAlertThreshold);
      }
    }
  }

  Future<void> _sendBudgetThresholdAlert(
    Budget budget,
    double spending,
    double percentage,
    int threshold,
  ) async {
    final remaining = budget.amount - spending;
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;

    final notification = AppNotification(
      id: _uuid.v4(),
      type: NotificationType.budget,
      priority: NotificationPriority.high,
      title: '⚠️ Budget Alert: ${budget.categoryName}',
      body: 'You\'ve spent \$${spending.toStringAsFixed(2)} of \$${budget.amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)\n\$${remaining.toStringAsFixed(2)} remaining for $daysLeft days',
      data: {
        'budgetId': budget.id,
        'categoryId': budget.categoryId,
        'percentage': percentage,
      },
      scheduledTime: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }

  Future<void> _sendBudgetExceededAlert(
    Budget budget,
    double spending,
    double percentage,
  ) async {
    final exceeded = spending - budget.amount;

    final notification = AppNotification(
      id: _uuid.v4(),
      type: NotificationType.budget,
      priority: NotificationPriority.urgent,
      title: '🚨 Budget Exceeded: ${budget.categoryName}',
      body: 'You\'ve spent \$${spending.toStringAsFixed(2)} of \$${budget.amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)\nOver budget by \$${exceeded.toStringAsFixed(2)}',
      data: {
        'budgetId': budget.id,
        'categoryId': budget.categoryId,
        'percentage': percentage,
      },
      scheduledTime: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }
}
