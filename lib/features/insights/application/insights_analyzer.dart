import 'dart:math';
import 'package:collection/collection.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../budget/domain/budget.dart';
import '../domain/spending_pattern.dart';
import '../domain/insight.dart';
import 'package:uuid/uuid.dart';

class InsightsAnalyzer {
  /// Analyze spending patterns for a category
  SpendingPattern analyzeCategory(
    String categoryId,
    List<Transaction> transactions,
  ) {
    final categoryTransactions = transactions
        .where((t) => t.categoryId == categoryId && t.type == TransactionType.expense)
        .toList();

    if (categoryTransactions.isEmpty) {
      return SpendingPattern(
        categoryId: categoryId,
        averageAmount: 0,
        frequency: 0,
        trend: SpendingTrend.stable,
        lastAmount: 0,
        percentageChange: 0,
        historicalAmounts: [],
      );
    }

    final amounts = categoryTransactions.map((t) => t.amount).toList();
    final average = amounts.average;
    final lastAmount = amounts.last;

    // Calculate trend using recent vs older data
    final trend = _calculateTrend(amounts);
    final percentageChange = _calculatePercentageChange(amounts);

    return SpendingPattern(
      categoryId: categoryId,
      averageAmount: average,
      frequency: categoryTransactions.length,
      trend: trend,
      lastAmount: lastAmount,
      percentageChange: percentageChange,
      historicalAmounts: amounts,
    );
  }

  /// Calculate spending trend
  SpendingTrend _calculateTrend(List<double> amounts) {
    if (amounts.length < 4) return SpendingTrend.stable;

    final recentCount = (amounts.length / 3).ceil();
    final recent = amounts.sublist(amounts.length - recentCount);
    final older = amounts.sublist(0, amounts.length - recentCount);

    final recentAvg = recent.average;
    final olderAvg = older.average;

    final change = ((recentAvg - olderAvg) / olderAvg) * 100;

    if (change > 15) return SpendingTrend.increasing;
    if (change < -15) return SpendingTrend.decreasing;
    return SpendingTrend.stable;
  }

  /// Calculate percentage change
  double _calculatePercentageChange(List<double> amounts) {
    if (amounts.length < 2) return 0;

    final recentCount = (amounts.length / 3).ceil();
    final recent = amounts.sublist(amounts.length - recentCount);
    final older = amounts.sublist(0, amounts.length - recentCount);

    final recentAvg = recent.average;
    final olderAvg = older.average;

    if (olderAvg == 0) return 0;
    return ((recentAvg - olderAvg) / olderAvg) * 100;
  }

  /// Detect anomalies using Z-score
  List<Transaction> detectAnomalies(
    List<Transaction> transactions,
    String categoryId,
  ) {
    final categoryTransactions = transactions
        .where((t) => t.categoryId == categoryId && t.type == TransactionType.expense)
        .toList();

    if (categoryTransactions.length < 5) return [];

    final amounts = categoryTransactions.map((t) => t.amount).toList();
    final mean = amounts.average;
    final stdDev = _calculateStdDev(amounts, mean);

    if (stdDev == 0) return [];

    final anomalies = <Transaction>[];
    for (final transaction in categoryTransactions) {
      final zScore = (transaction.amount - mean) / stdDev;
      if (zScore.abs() > 2) {
        // More than 2 standard deviations
        anomalies.add(transaction);
      }
    }

    return anomalies;
  }

  /// Calculate standard deviation
  double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0;
    final variance = values.map((v) => pow(v - mean, 2)).average;
    return sqrt(variance);
  }

  /// Predict next month's spending using linear regression
  double predictNextMonthSpending(List<double> monthlySpending) {
    if (monthlySpending.length < 2) {
      return monthlySpending.isNotEmpty ? monthlySpending.last : 0;
    }

    // Simple linear regression
    final n = monthlySpending.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = monthlySpending;

    final xMean = x.average;
    final yMean = y.average;

    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      numerator += (x[i] - xMean) * (y[i] - yMean);
      denominator += pow(x[i] - xMean, 2);
    }

    if (denominator == 0) return yMean;

    final slope = numerator / denominator;
    final intercept = yMean - slope * xMean;

    // Predict for next month (n)
    return slope * n + intercept;
  }

  /// Generate trend insights
  List<Insight> generateTrendInsights(
    Map<String, SpendingPattern> patterns,
    Map<String, String> categoryNames,
  ) {
    final insights = <Insight>[];

    for (final entry in patterns.entries) {
      final categoryId = entry.key;
      final pattern = entry.value;
      final categoryName = categoryNames[categoryId] ?? 'Unknown';

      if (pattern.isSignificantChange) {
        final changeDirection = pattern.isIncreasing ? 'increased' : 'decreased';
        final emoji = pattern.isIncreasing ? '📈' : '📉';

        insights.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.trend.name,
          title: '$emoji $categoryName spending $changeDirection',
          description:
              'Your $categoryName spending $changeDirection by ${pattern.percentageChange.abs().toStringAsFixed(1)}% '
              '(\$${pattern.lastAmount.toStringAsFixed(2)} vs \$${pattern.averageAmount.toStringAsFixed(2)} average)',
          priority: pattern.percentageChange.abs() > 50
              ? InsightPriority.high.name
              : InsightPriority.medium.name,
          categoryId: categoryId,
          metadata: {
            'percentageChange': pattern.percentageChange,
            'currentAmount': pattern.lastAmount,
            'averageAmount': pattern.averageAmount,
          },
        ));
      }
    }

    return insights;
  }

  /// Generate anomaly insights
  List<Insight> generateAnomalyInsights(
    Map<String, List<Transaction>> anomaliesByCategory,
    Map<String, String> categoryNames,
    Map<String, double> categoryAverages,
  ) {
    final insights = <Insight>[];

    for (final entry in anomaliesByCategory.entries) {
      final categoryId = entry.key;
      final anomalies = entry.value;
      final categoryName = categoryNames[categoryId] ?? 'Unknown';
      final average = categoryAverages[categoryId] ?? 0;

      for (final transaction in anomalies) {
        final multiplier = (transaction.amount / average).toStringAsFixed(1);

        insights.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.warning.name,
          title: '⚠️ Unusual $categoryName transaction',
          description:
              'Transaction of \$${transaction.amount.toStringAsFixed(2)} is ${multiplier}x your average '
              '(\$${average.toStringAsFixed(2)})',
          priority: InsightPriority.high.name,
          categoryId: categoryId,
          actionable: true,
          metadata: {
            'transactionId': transaction.id,
            'amount': transaction.amount,
            'average': average,
            'multiplier': double.parse(multiplier),
          },
        ));
      }
    }

    return insights;
  }

  /// Generate budget insights
  List<Insight> generateBudgetInsights(
    List<Budget> budgets,
    Map<String, double> categorySpending,
    Map<String, String> categoryNames,
  ) {
    final insights = <Insight>[];

    for (final budget in budgets) {
      final spent = categorySpending[budget.categoryId] ?? 0;
      final percentage = (spent / budget.amount) * 100;
      final categoryName = categoryNames[budget.categoryId] ?? 'Unknown';

      if (percentage >= 100) {
        insights.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.warning.name,
          title: '🚨 $categoryName budget exceeded',
          description:
              'You\'ve spent \$${spent.toStringAsFixed(2)} of \$${budget.amount.toStringAsFixed(2)} '
              '(${percentage.toStringAsFixed(0)}%)',
          priority: InsightPriority.critical.name,
          categoryId: budget.categoryId,
          actionable: true,
          metadata: {
            'spent': spent,
            'budget': budget.amount,
            'percentage': percentage,
            'overspent': spent - budget.amount,
          },
        ));
      } else if (percentage >= 80) {
        insights.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.warning.name,
          title: '⏰ $categoryName budget running low',
          description:
              'You\'ve used ${percentage.toStringAsFixed(0)}% of your $categoryName budget '
              '(\$${spent.toStringAsFixed(2)} of \$${budget.amount.toStringAsFixed(2)})',
          priority: InsightPriority.medium.name,
          categoryId: budget.categoryId,
          metadata: {
            'spent': spent,
            'budget': budget.amount,
            'percentage': percentage,
            'remaining': budget.amount - spent,
          },
        ));
      }
    }

    return insights;
  }

  /// Generate prediction insights
  List<Insight> generatePredictionInsights(
    double predictedSpending,
    double currentMonthSpending,
    List<double> historicalSpending,
  ) {
    final insights = <Insight>[];
    final average = historicalSpending.average;
    final change = ((predictedSpending - average) / average) * 100;

    if (change.abs() > 10) {
      final direction = change > 0 ? 'higher' : 'lower';
      final emoji = change > 0 ? '📈' : '📉';

      insights.add(Insight(
        id: const Uuid().v4(),
        type: InsightType.prediction.name,
        title: '$emoji Next month projection',
        description:
            'Based on your spending trends, next month\'s expenses are projected to be '
            '\$${predictedSpending.toStringAsFixed(2)} (${change.abs().toStringAsFixed(1)}% $direction than average)',
        priority: change.abs() > 30 ? InsightPriority.high.name : InsightPriority.medium.name,
        metadata: {
          'predicted': predictedSpending,
          'average': average,
          'change': change,
        },
      ));
    }

    return insights;
  }
}

extension _ListAverage on List<double> {
  double get average {
    if (isEmpty) return 0;
    return reduce((a, b) => a + b) / length;
  }
}
