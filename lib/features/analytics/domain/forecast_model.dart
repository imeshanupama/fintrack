/// Represents a spending forecast for a specific period
class ForecastModel {
  final DateTime forecastDate;
  final double predictedAmount;
  final double confidenceLow; // Lower bound of confidence interval
  final double confidenceHigh; // Upper bound of confidence interval
  final String trend; // 'increasing', 'decreasing', 'stable'
  final double trendPercentage; // Percentage change from current
  final Map<String, double> categoryBreakdown; // Predicted spending by category
  final String? reason; // Why this prediction was made

  ForecastModel({
    required this.forecastDate,
    required this.predictedAmount,
    required this.confidenceLow,
    required this.confidenceHigh,
    required this.trend,
    required this.trendPercentage,
    required this.categoryBreakdown,
    this.reason,
  });

  /// Get confidence range as a percentage
  double get confidenceRange => ((confidenceHigh - confidenceLow) / predictedAmount * 100).abs();

  /// Check if prediction is reliable (narrow confidence range)
  bool get isReliable => confidenceRange < 30; // Less than 30% variance

  /// Get trend icon
  String get trendIcon {
    switch (trend) {
      case 'increasing':
        return '↑';
      case 'decreasing':
        return '↓';
      default:
        return '→';
    }
  }

  /// Get trend description
  String get trendDescription {
    final absPercentage = trendPercentage.abs().toStringAsFixed(1);
    switch (trend) {
      case 'increasing':
        return 'Up $absPercentage% from current';
      case 'decreasing':
        return 'Down $absPercentage% from current';
      default:
        return 'Stable (±$absPercentage%)';
    }
  }

  /// Format predicted amount with confidence range
  String formatPrediction({required String currencySymbol}) {
    return '$currencySymbol${predictedAmount.toStringAsFixed(2)} (±${confidenceRange.toStringAsFixed(0)}%)';
  }
}

/// Represents a category-specific forecast
class CategoryForecast {
  final String categoryId;
  final String categoryName;
  final double predictedAmount;
  final double currentMonthAmount;
  final String trend;
  final double changePercentage;

  CategoryForecast({
    required this.categoryId,
    required this.categoryName,
    required this.predictedAmount,
    required this.currentMonthAmount,
    required this.trend,
    required this.changePercentage,
  });

  bool get isIncreasing => trend == 'increasing';
  bool get isDecreasing => trend == 'decreasing';
  bool get isStable => trend == 'stable';
}
