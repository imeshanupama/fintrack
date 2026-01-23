import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/presentation/transactions_provider.dart';

class AnalyticsState {
  // Weekly (Last 7 Days)
  final Map<String, double> weeklyCategorySpending;
  final Map<int, double> weeklyChartData; // 0-6 (Days ago)

  // Monthly (Current Month)
  final Map<String, double> monthlyCategorySpending;
  final Map<int, double> monthlyChartData; // 1-31 (Day of month)

  // Yearly (Current Year)
  final Map<String, double> yearlyCategorySpending;
  final Map<int, double> yearlyChartData; // 1-12 (Month of year)
  
  // Income vs Expense maps for all above... 
  // To keep it simple, let's nest them or just duplicate for now.
  // Actually, the UI toggle handles Income/Expense. The provider should provide data for BOTH.
  
  final Map<String, double> incomeWeeklyCategory;
  final Map<int, double> incomeWeeklyChart;
  final Map<String, double> incomeMonthlyCategory;
  final Map<int, double> incomeMonthlyChart;
  final Map<String, double> incomeYearlyCategory;
  final Map<int, double> incomeYearlyChart;

  // Previous period data for comparisons
  final Map<int, double> previousWeeklyChartData;
  final Map<int, double> previousMonthlyChartData;
  final Map<int, double> previousYearlyChartData;
  final Map<int, double> previousIncomeWeeklyChart;
  final Map<int, double> previousIncomeMonthlyChart;
  final Map<int, double> previousIncomeYearlyChart;

  AnalyticsState({
    required this.weeklyCategorySpending,
    required this.weeklyChartData,
    required this.monthlyCategorySpending,
    required this.monthlyChartData,
    required this.yearlyCategorySpending,
    required this.yearlyChartData,
    required this.incomeWeeklyCategory,
    required this.incomeWeeklyChart,
    required this.incomeMonthlyCategory,
    required this.incomeMonthlyChart,
    required this.incomeYearlyCategory,
    required this.incomeYearlyChart,
    required this.previousWeeklyChartData,
    required this.previousMonthlyChartData,
    required this.previousYearlyChartData,
    required this.previousIncomeWeeklyChart,
    required this.previousIncomeMonthlyChart,
    required this.previousIncomeYearlyChart,
  });
}

final analyticsProvider = Provider<AnalyticsState>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();

  // --- FILTERS ---
  
  // Weekly: Last 7 days
  final weeklyTxs = transactions.where((t) {
    final diff = now.difference(t.date).inDays;
    return diff >= 0 && diff < 7;
  }).toList();

  // Previous Week: 7-14 days ago
  final previousWeeklyTxs = transactions.where((t) {
    final diff = now.difference(t.date).inDays;
    return diff >= 7 && diff < 14;
  }).toList();

  // Monthly: Current Month
  final monthlyTxs = transactions.where((t) {
    return t.date.year == now.year && t.date.month == now.month;
  }).toList();

  // Previous Month
  final previousMonth = DateTime(now.year, now.month - 1);
  final previousMonthlyTxs = transactions.where((t) {
    return t.date.year == previousMonth.year && t.date.month == previousMonth.month;
  }).toList();

  // Yearly: Current Year
  final yearlyTxs = transactions.where((t) {
    return t.date.year == now.year;
  }).toList();

  // Previous Year
  final previousYearlyTxs = transactions.where((t) {
    return t.date.year == now.year - 1;
  }).toList();

  // --- SPLIT INCOME/EXPENSE ---
  
  List<Transaction> getExpenses(List<Transaction> txs) => txs.where((t) => t.type == TransactionType.expense).toList();
  List<Transaction> getIncome(List<Transaction> txs) => txs.where((t) => t.type == TransactionType.income).toList();

  // --- HELPERS ---

  Map<String, double> calculateCategories(List<Transaction> txs) {
    final map = <String, double>{};
    for (var t in txs) {
      map.update(t.categoryId, (val) => val + t.amount, ifAbsent: () => t.amount);
    }
    return map;
  }

  // 0-6 (Days ago)
  Map<int, double> calculateWeeklyChart(List<Transaction> txs) {
    final map = <int, double>{};
    for (int i = 0; i < 7; i++) map[i] = 0;
    for (var t in txs) {
      final diff = now.difference(t.date).inDays;
      if (diff >= 0 && diff < 7) {
        map.update(diff, (val) => val + t.amount, ifAbsent: () => t.amount);
      }
    }
    return map;
  }

  // Previous week chart (7-14 days ago, mapped to 0-6)
  Map<int, double> calculatePreviousWeeklyChart(List<Transaction> txs) {
    final map = <int, double>{};
    for (int i = 0; i < 7; i++) map[i] = 0;
    for (var t in txs) {
      final diff = now.difference(t.date).inDays;
      if (diff >= 7 && diff < 14) {
        final index = diff - 7; // Map to 0-6
        map.update(index, (val) => val + t.amount, ifAbsent: () => t.amount);
      }
    }
    return map;
  }

  // 1-31 (Day of Month)
  Map<int, double> calculateMonthlyChart(List<Transaction> txs) {
    final map = <int, double>{};
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    for (int i = 1; i <= daysInMonth; i++) map[i] = 0;
    
    for (var t in txs) {
      map.update(t.date.day, (val) => val + t.amount, ifAbsent: () => t.amount);
    }
    return map;
  }

  // Previous month chart
  Map<int, double> calculatePreviousMonthlyChart(List<Transaction> txs) {
    final map = <int, double>{};
    final daysInPrevMonth = DateUtils.getDaysInMonth(previousMonth.year, previousMonth.month);
    for (int i = 1; i <= daysInPrevMonth; i++) map[i] = 0;
    
    for (var t in txs) {
      map.update(t.date.day, (val) => val + t.amount, ifAbsent: () => t.amount);
    }
    return map;
  }

  // 1-12 (Month of Year)
  Map<int, double> calculateYearlyChart(List<Transaction> txs) {
    final map = <int, double>{};
    for (int i = 1; i <= 12; i++) map[i] = 0;
    
    for (var t in txs) {
      map.update(t.date.month, (val) => val + t.amount, ifAbsent: () => t.amount);
    }
    return map;
  }

  return AnalyticsState(
    weeklyCategorySpending: calculateCategories(getExpenses(weeklyTxs)),
    weeklyChartData: calculateWeeklyChart(getExpenses(weeklyTxs)),
    monthlyCategorySpending: calculateCategories(getExpenses(monthlyTxs)),
    monthlyChartData: calculateMonthlyChart(getExpenses(monthlyTxs)),
    yearlyCategorySpending: calculateCategories(getExpenses(yearlyTxs)),
    yearlyChartData: calculateYearlyChart(getExpenses(yearlyTxs)),
    
    incomeWeeklyCategory: calculateCategories(getIncome(weeklyTxs)),
    incomeWeeklyChart: calculateWeeklyChart(getIncome(weeklyTxs)),
    incomeMonthlyCategory: calculateCategories(getIncome(monthlyTxs)),
    incomeMonthlyChart: calculateMonthlyChart(getIncome(monthlyTxs)),
    incomeYearlyCategory: calculateCategories(getIncome(yearlyTxs)),
    incomeYearlyChart: calculateYearlyChart(getIncome(yearlyTxs)),

    // Previous period data
    previousWeeklyChartData: calculatePreviousWeeklyChart(getExpenses(previousWeeklyTxs)),
    previousMonthlyChartData: calculatePreviousMonthlyChart(getExpenses(previousMonthlyTxs)),
    previousYearlyChartData: calculateYearlyChart(getExpenses(previousYearlyTxs)),
    previousIncomeWeeklyChart: calculatePreviousWeeklyChart(getIncome(previousWeeklyTxs)),
    previousIncomeMonthlyChart: calculatePreviousMonthlyChart(getIncome(previousMonthlyTxs)),
    previousIncomeYearlyChart: calculateYearlyChart(getIncome(previousYearlyTxs)),
  );
});
