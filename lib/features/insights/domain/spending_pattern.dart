enum SpendingTrend {
  increasing,
  decreasing,
  stable,
}

class SpendingPattern {
  final String categoryId;
  final double averageAmount;
  final int frequency; // Number of transactions in period
  final SpendingTrend trend;
  final double lastAmount;
  final double percentageChange;
  final List<double> historicalAmounts;

  SpendingPattern({
    required this.categoryId,
    required this.averageAmount,
    required this.frequency,
    required this.trend,
    required this.lastAmount,
    required this.percentageChange,
    required this.historicalAmounts,
  });

  bool get isIncreasing => trend == SpendingTrend.increasing;
  bool get isDecreasing => trend == SpendingTrend.decreasing;
  bool get isStable => trend == SpendingTrend.stable;

  bool get isSignificantChange => percentageChange.abs() > 20; // >20% change

  double get totalSpent => historicalAmounts.fold(0.0, (sum, amount) => sum + amount);
}
