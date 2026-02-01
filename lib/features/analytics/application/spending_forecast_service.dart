import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/forecast_model.dart';
import 'dart:math';

final spendingForecastServiceProvider = Provider<SpendingForecastService>((ref) {
  return SpendingForecastService();
});

class SpendingForecastService {
  /// Predict next month's total spending
  Future<ForecastModel> predictNextMonthSpending({
    required List<Transaction> transactions,
    required Map<String, String> categoryNames,
  }) async {
    // Filter expense transactions only
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) {
      return _createEmptyForecast();
    }

    // Group by month
    final monthlySpending = _groupByMonth(expenses);
    
    if (monthlySpending.isEmpty) {
      return _createEmptyForecast();
    }

    // Get monthly totals
    final monthlyTotals = monthlySpending.values.map((txs) {
      return txs.fold<double>(0, (sum, tx) => sum + tx.amount);
    }).toList();

    // Calculate prediction using linear regression
    final predicted = _linearRegression(monthlyTotals);
    
    // Calculate confidence interval
    final stdDev = _calculateStdDev(monthlyTotals, monthlyTotals.average);
    final confidenceLow = (predicted - stdDev * 1.96).clamp(0, double.infinity);
    final confidenceHigh = predicted + stdDev * 1.96;

    // Determine trend
    final currentMonth = monthlyTotals.isNotEmpty ? monthlyTotals.last : 0;
    final trendPercentage = currentMonth > 0 
        ? ((predicted - currentMonth) / currentMonth * 100)
        : 0;
    
    String trend;
    if (trendPercentage > 5) {
      trend = 'increasing';
    } else if (trendPercentage < -5) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }

    // Category breakdown
    final categoryBreakdown = await _predictCategoryBreakdown(
      transactions: expenses,
      categoryNames: categoryNames,
    );

    return ForecastModel(
      forecastDate: DateTime.now().add(const Duration(days: 30)),
      predictedAmount: predicted,
      confidenceLow: confidenceLow,
      confidenceHigh: confidenceHigh,
      trend: trend,
      trendPercentage: trendPercentage,
      categoryBreakdown: categoryBreakdown,
      reason: _generateReason(trend, monthlyTotals.length),
    );
  }

  /// Predict spending for specific categories
  Future<List<CategoryForecast>> predictCategorySpending({
    required List<Transaction> transactions,
    required Map<String, String> categoryNames,
  }) async {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) return [];

    final forecasts = <CategoryForecast>[];
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    
    // Group by category
    final byCategory = <String, List<Transaction>>{};
    for (final tx in expenses) {
      byCategory.putIfAbsent(tx.categoryId, () => []).add(tx);
    }

    for (final entry in byCategory.entries) {
      final categoryId = entry.key;
      final categoryTxs = entry.value;
      
      // Get current month spending
      final currentMonthTxs = categoryTxs
          .where((t) => t.date.isAfter(currentMonthStart))
          .toList();
      final currentAmount = currentMonthTxs.fold<double>(
        0,
        (sum, tx) => sum + tx.amount,
      );

      // Get historical monthly averages
      final monthlyData = _groupByMonth(categoryTxs);
      final monthlyTotals = monthlyData.values.map((txs) {
        return txs.fold<double>(0, (sum, tx) => sum + tx.amount);
      }).toList();

      if (monthlyTotals.isEmpty) continue;

      // Predict next month
      final predicted = monthlyTotals.length >= 3
          ? _linearRegression(monthlyTotals)
          : monthlyTotals.average;

      // Calculate trend
      final changePercentage = currentAmount > 0
          ? ((predicted - currentAmount) / currentAmount * 100)
          : 0;

      String trend;
      if (changePercentage > 10) {
        trend = 'increasing';
      } else if (changePercentage < -10) {
        trend = 'decreasing';
      } else {
        trend = 'stable';
      }

      forecasts.add(CategoryForecast(
        categoryId: categoryId,
        categoryName: categoryNames[categoryId] ?? 'Unknown',
        predictedAmount: predicted,
        currentMonthAmount: currentAmount,
        trend: trend,
        changePercentage: changePercentage,
      ));
    }

    // Sort by predicted amount (highest first)
    forecasts.sort((a, b) => b.predictedAmount.compareTo(a.predictedAmount));

    return forecasts;
  }

  /// Calculate "What-If" scenario
  Future<double> calculateWhatIf({
    required List<Transaction> transactions,
    required String categoryId,
    required double reductionPercentage,
  }) async {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Get current prediction
    final monthlySpending = _groupByMonth(expenses);
    final monthlyTotals = monthlySpending.values.map((txs) {
      return txs.fold<double>(0, (sum, tx) => sum + tx.amount);
    }).toList();

    final basePrediction = monthlyTotals.isNotEmpty
        ? _linearRegression(monthlyTotals)
        : 0;

    // Calculate category's contribution
    final categoryExpenses = expenses.where((t) => t.categoryId == categoryId).toList();
    final categoryMonthly = _groupByMonth(categoryExpenses);
    final categoryTotals = categoryMonthly.values.map((txs) {
      return txs.fold<double>(0, (sum, tx) => sum + tx.amount);
    }).toList();

    final categoryPrediction = categoryTotals.isNotEmpty
        ? _linearRegression(categoryTotals)
        : 0;

    // Apply reduction
    final reduction = categoryPrediction * (reductionPercentage / 100);
    return basePrediction - reduction;
  }

  /// Detect seasonal patterns
  Map<int, double> detectSeasonalPatterns(List<Transaction> transactions) {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Group by month of year (1-12)
    final byMonth = <int, List<double>>{};
    
    for (final tx in expenses) {
      final month = tx.date.month;
      byMonth.putIfAbsent(month, () => []).add(tx.amount);
    }

    // Calculate average for each month
    final seasonalPattern = <int, double>{};
    byMonth.forEach((month, amounts) {
      seasonalPattern[month] = amounts.average;
    });

    return seasonalPattern;
  }

  // Helper methods

  Map<String, List<Transaction>> _groupByMonth(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    
    for (final tx in transactions) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return grouped;
  }

  double _linearRegression(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;

    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Predict next value
    return slope * n + intercept;
  }

  double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0;
    
    final variance = values
        .map((v) => pow(v - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return sqrt(variance);
  }

  Future<Map<String, double>> _predictCategoryBreakdown({
    required List<Transaction> transactions,
    required Map<String, String> categoryNames,
  }) async {
    final breakdown = <String, double>{};
    
    // Group by category
    final byCategory = <String, List<Transaction>>{};
    for (final tx in transactions) {
      byCategory.putIfAbsent(tx.categoryId, () => []).add(tx);
    }

    // Predict each category
    for (final entry in byCategory.entries) {
      final categoryId = entry.key;
      final categoryTxs = entry.value;
      
      final monthlyData = _groupByMonth(categoryTxs);
      final monthlyTotals = monthlyData.values.map((txs) {
        return txs.fold<double>(0, (sum, tx) => sum + tx.amount);
      }).toList();

      if (monthlyTotals.isNotEmpty) {
        final predicted = monthlyTotals.length >= 3
            ? _linearRegression(monthlyTotals)
            : monthlyTotals.average;
        
        breakdown[categoryId] = predicted;
      }
    }

    return breakdown;
  }

  ForecastModel _createEmptyForecast() {
    return ForecastModel(
      forecastDate: DateTime.now().add(const Duration(days: 30)),
      predictedAmount: 0,
      confidenceLow: 0,
      confidenceHigh: 0,
      trend: 'stable',
      trendPercentage: 0,
      categoryBreakdown: {},
      reason: 'Not enough data to make a prediction',
    );
  }

  String _generateReason(String trend, int dataPoints) {
    if (dataPoints < 3) {
      return 'Based on limited historical data';
    }

    switch (trend) {
      case 'increasing':
        return 'Based on upward trend in recent months';
      case 'decreasing':
        return 'Based on downward trend in recent months';
      default:
        return 'Based on stable spending pattern';
    }
  }
}

extension _ListAverage on List<double> {
  double get average {
    if (isEmpty) return 0;
    return reduce((a, b) => a + b) / length;
  }
}
