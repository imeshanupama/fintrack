import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/insight.dart';
import '../data/insights_repository.dart';
import '../application/insights_analyzer.dart';
import '../application/recommendations_service.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../budget/presentation/budget_provider.dart';
import '../../categories/presentation/category_provider.dart';
import '../../savings/presentation/savings_provider.dart';
import '../domain/spending_pattern.dart';
import '../../transactions/domain/transaction.dart';

// Providers
final insightsAnalyzerProvider = Provider((ref) => InsightsAnalyzer());
final recommendationsServiceProvider = Provider((ref) => RecommendationsService());

// Stream provider for active insights
final activeInsightsProvider = StreamProvider<List<Insight>>((ref) {
  final repository = ref.watch(insightsRepositoryProvider);
  return repository.watchActiveInsights();
});

// Provider for insights by type
final insightsByTypeProvider = Provider.family<List<Insight>, InsightType>((ref, type) {
  final repository = ref.watch(insightsRepositoryProvider);
  return repository.getInsightsByType(type);
});

// Provider for insights by category
final insightsByCategoryProvider = Provider.family<List<Insight>, String>((ref, categoryId) {
  final repository = ref.watch(insightsRepositoryProvider);
  return repository.getInsightsByCategory(categoryId);
});

// Simple notifier for managing insights
final insightsNotifierProvider = NotifierProvider<InsightsNotifier, AsyncValue<List<Insight>>>(InsightsNotifier.new);

class InsightsNotifier extends Notifier<AsyncValue<List<Insight>>> {
  @override
  AsyncValue<List<Insight>> build() {
    final repository = ref.read(insightsRepositoryProvider);
    return AsyncValue.data(repository.getActiveInsights());
  }

  // Generate all insights
  Future<void> generateInsights() async {
    state = const AsyncValue.loading();
    
    try {
      final analyzer = ref.read(insightsAnalyzerProvider);
      final recommendationsService = ref.read(recommendationsServiceProvider);
      final repository = ref.read(insightsRepositoryProvider);

      // Get data
      final transactions = ref.read(transactionsProvider);
      final budgets = ref.read(budgetProvider);
      final categories = ref.read(categoryProvider);
      final savingsGoals = ref.read(savingsProvider);

      // Create category maps
      final categoryNames = {for (var c in categories) c.id: c.name};
      final categoryIds = categories.map((c) => c.id).toList();

      // Calculate current month spending by category
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final currentMonthTransactions = transactions
          .where((t) => t.date.isAfter(startOfMonth))
          .toList();

      final categorySpending = <String, double>{};
      for (final transaction in currentMonthTransactions) {
        if (transaction.type.name == 'expense') {
          categorySpending[transaction.categoryId] =
              (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
        }
      }

      final allInsights = <Insight>[];

      // 1. Analyze spending patterns and generate trend insights
      final patterns = <String, SpendingPattern>{};
      for (final categoryId in categoryIds) {
        final pattern = analyzer.analyzeCategory(categoryId, transactions);
        if (pattern.frequency > 0) {
          patterns[categoryId] = pattern;
        }
      }
      allInsights.addAll(analyzer.generateTrendInsights(patterns, categoryNames));

      // 2. Detect anomalies
      final anomaliesByCategory = <String, List<Transaction>>{};
      for (final categoryId in categoryIds) {
        final anomalies = analyzer.detectAnomalies(transactions, categoryId);
        if (anomalies.isNotEmpty) {
          anomaliesByCategory[categoryId] = anomalies;
        }
      }
      final categoryAverages = <String, double>{
        for (var entry in patterns.entries) entry.key: entry.value.averageAmount
      };
      allInsights.addAll(
        analyzer.generateAnomalyInsights(anomaliesByCategory, categoryNames, categoryAverages),
      );

      // 3. Generate budget insights
      allInsights.addAll(
        analyzer.generateBudgetInsights(budgets, categorySpending, categoryNames),
      );

      // 4. Generate predictions
      final monthlySpending = <double>[];
      for (int i = 5; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        final monthTransactions = transactions.where((t) =>
            t.type.name == 'expense' &&
            t.date.isAfter(monthStart) &&
            t.date.isBefore(monthEnd)).toList();
        final total = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);
        monthlySpending.add(total);
      }

      if (monthlySpending.length >= 3) {
        final predicted = analyzer.predictNextMonthSpending(monthlySpending);
        final currentMonth = monthlySpending.last;
        allInsights.addAll(
          analyzer.generatePredictionInsights(predicted, currentMonth, monthlySpending),
        );
      }

      // 5. Generate recommendations
      allInsights.addAll(
        recommendationsService.generateBudgetRecommendations(budgets, categorySpending, categoryNames),
      );

      allInsights.addAll(
        recommendationsService.detectSavingsOpportunities(patterns, categoryNames),
      );

      final monthlyIncome = currentMonthTransactions
          .where((t) => t.type.name == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
      final monthlyExpenses = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);

      allInsights.addAll(
        recommendationsService.generateGoalRecommendations(savingsGoals, monthlyIncome, monthlyExpenses),
      );

      allInsights.addAll(
        recommendationsService.detectDuplicateSubscriptions(transactions, categoryNames),
      );

      allInsights.addAll(
        recommendationsService.generateSpendingReductionTips(categorySpending, categoryNames),
      );

      // Save all insights
      await repository.saveInsights(allInsights);

      // Reload state
      state = AsyncValue.data(repository.getActiveInsights());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Dismiss insight
  Future<void> dismissInsight(String id) async {
    final repository = ref.read(insightsRepositoryProvider);
    await repository.dismissInsight(id);
    state = AsyncValue.data(repository.getActiveInsights());
  }

  // Clear old insights
  Future<void> clearOldInsights({int daysToKeep = 30}) async {
    final repository = ref.read(insightsRepositoryProvider);
    await repository.clearOldInsights(daysToKeep: daysToKeep);
    state = AsyncValue.data(repository.getActiveInsights());
  }
}
