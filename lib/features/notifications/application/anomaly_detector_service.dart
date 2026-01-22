import '../domain/notification.dart';
import '../domain/notification_settings.dart';
import '../../transactions/domain/transaction.dart';
import 'notification_service.dart';
import 'package:uuid/uuid.dart';

class AnomalyDetectorService {
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  AnomalyDetectorService(this._notificationService);

  Future<void> checkAnomalies({
    required List<Transaction> transactions,
    required NotificationSettings settings,
  }) async {
    if (!settings.anomalyAlertsEnabled || !settings.notificationsEnabled) {
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get today's transactions
    final todayTransactions = transactions.where((t) {
      final txDate = DateTime(t.date.year, t.date.month, t.date.day);
      return txDate.isAtSameMomentAs(today) && t.type.name == 'expense';
    }).toList();

    if (todayTransactions.isEmpty) return;

    // Calculate historical averages by category
    final categoryAverages = _calculateCategoryAverages(transactions);

    // Check each transaction for anomalies
    for (final transaction in todayTransactions) {
      final average = categoryAverages[transaction.categoryId] ?? 0;
      
      // Skip if no historical data
      if (average == 0) continue;

      // Check if transaction exceeds threshold
      final multiplier = transaction.amount / average;
      if (multiplier >= settings.anomalyThresholdMultiplier) {
        await _sendAnomalyAlert(transaction, average, multiplier);
      }
    }

    // Check total daily spending
    final todayTotal = todayTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final avgDailySpending = _calculateAverageDailySpending(transactions);
    
    if (avgDailySpending > 0) {
      final dailyMultiplier = todayTotal / avgDailySpending;
      if (dailyMultiplier >= settings.anomalyThresholdMultiplier) {
        await _sendDailySpendingAlert(todayTotal, avgDailySpending, dailyMultiplier);
      }
    }
  }

  Map<String, double> _calculateCategoryAverages(List<Transaction> transactions) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get last 30 days of transactions
    final recentTransactions = transactions.where((t) =>
        t.date.isAfter(thirtyDaysAgo) &&
        t.type.name == 'expense').toList();

    // Group by category
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final transaction in recentTransactions) {
      categoryTotals[transaction.categoryId] =
          (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
      categoryCounts[transaction.categoryId] =
          (categoryCounts[transaction.categoryId] ?? 0) + 1;
    }

    // Calculate averages
    final averages = <String, double>{};
    for (final categoryId in categoryTotals.keys) {
      averages[categoryId] = categoryTotals[categoryId]! / categoryCounts[categoryId]!;
    }

    return averages;
  }

  double _calculateAverageDailySpending(List<Transaction> transactions) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentExpenses = transactions.where((t) =>
        t.date.isAfter(thirtyDaysAgo) &&
        t.type.name == 'expense').toList();

    if (recentExpenses.isEmpty) return 0;

    final total = recentExpenses.fold(0.0, (sum, t) => sum + t.amount);
    return total / 30; // Average per day over 30 days
  }

  Future<void> _sendAnomalyAlert(
    Transaction transaction,
    double average,
    double multiplier,
  ) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      type: NotificationType.anomaly,
      priority: NotificationPriority.high,
      title: '⚡ Unusual Spending Detected',
      body: '\$${transaction.amount.toStringAsFixed(2)} on ${transaction.note.isEmpty ? "transaction" : transaction.note}\nThis is ${multiplier.toStringAsFixed(1)}x your average (\$${average.toStringAsFixed(2)})',
      data: {
        'transactionId': transaction.id,
        'categoryId': transaction.categoryId,
        'amount': transaction.amount,
        'average': average,
        'multiplier': multiplier,
      },
      scheduledTime: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }

  Future<void> _sendDailySpendingAlert(
    double todayTotal,
    double average,
    double multiplier,
  ) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      type: NotificationType.anomaly,
      priority: NotificationPriority.high,
      title: '⚡ High Spending Day',
      body: 'You\'ve spent \$${todayTotal.toStringAsFixed(2)} today\nThis is ${multiplier.toStringAsFixed(1)}x your daily average (\$${average.toStringAsFixed(2)})',
      data: {
        'todayTotal': todayTotal,
        'average': average,
        'multiplier': multiplier,
      },
      scheduledTime: DateTime.now(),
    );

    await _notificationService.showNotification(notification);
  }
}
