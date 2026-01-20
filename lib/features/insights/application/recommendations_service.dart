import 'package:uuid/uuid.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../budget/domain/budget.dart';
import '../../savings/domain/savings_goal.dart';
import '../domain/insight.dart';
import '../domain/spending_pattern.dart';

class RecommendationsService {
  /// Generate budget optimization recommendations
  List<Insight> generateBudgetRecommendations(
    List<Budget> budgets,
    Map<String, double> categorySpending,
    Map<String, String> categoryNames,
  ) {
    final recommendations = <Insight>[];

    for (final budget in budgets) {
      final spent = categorySpending[budget.categoryId] ?? 0;
      final percentage = (spent / budget.amount) * 100;
      final categoryName = categoryNames[budget.categoryId] ?? 'Unknown';

      // Recommend budget increase for consistently overspent categories
      if (percentage > 120) {
        final suggestedBudget = (spent * 1.1).ceil().toDouble(); // 10% buffer
        recommendations.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.recommendation.name,
          title: '💡 Increase $categoryName budget',
          description:
              'You consistently overspend in $categoryName. Consider increasing your budget to '
              '\$${suggestedBudget.toStringAsFixed(0)} (currently \$${budget.amount.toStringAsFixed(0)})',
          priority: InsightPriority.medium.name,
          categoryId: budget.categoryId,
          actionable: true,
          metadata: {
            'currentBudget': budget.amount,
            'suggestedBudget': suggestedBudget,
            'currentSpending': spent,
          },
        ));
      }

      // Recommend budget decrease for significantly underspent categories
      if (percentage < 50 && budget.amount > 100) {
        final suggestedBudget = (spent * 1.2).ceil().toDouble(); // 20% buffer
        recommendations.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.recommendation.name,
          title: '💰 Reallocate $categoryName budget',
          description:
              'You only used ${percentage.toStringAsFixed(0)}% of your $categoryName budget. '
              'Consider reducing it to \$${suggestedBudget.toStringAsFixed(0)} and reallocating \$${(budget.amount - suggestedBudget).toStringAsFixed(0)} to savings',
          priority: InsightPriority.low.name,
          categoryId: budget.categoryId,
          actionable: true,
          metadata: {
            'currentBudget': budget.amount,
            'suggestedBudget': suggestedBudget,
            'savingsOpportunity': budget.amount - suggestedBudget,
          },
        ));
      }
    }

    return recommendations;
  }

  /// Detect savings opportunities
  List<Insight> detectSavingsOpportunities(
    Map<String, SpendingPattern> patterns,
    Map<String, String> categoryNames,
  ) {
    final opportunities = <Insight>[];

    for (final entry in patterns.entries) {
      final categoryId = entry.key;
      final pattern = entry.value;
      final categoryName = categoryNames[categoryId] ?? 'Unknown';

      // High frequency, low amount transactions (potential subscription/habit)
      if (pattern.frequency > 20 && pattern.averageAmount < 20) {
        final monthlySavings = pattern.averageAmount * (pattern.frequency * 0.3); // 30% reduction
        opportunities.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.recommendation.name,
          title: '☕ Reduce $categoryName frequency',
          description:
              'You have ${pattern.frequency} $categoryName transactions averaging \$${pattern.averageAmount.toStringAsFixed(2)}. '
              'Reducing by 30% could save you \$${monthlySavings.toStringAsFixed(2)}/month',
          priority: InsightPriority.medium.name,
          categoryId: categoryId,
          actionable: true,
          metadata: {
            'frequency': pattern.frequency,
            'averageAmount': pattern.averageAmount,
            'potentialSavings': monthlySavings,
          },
        ));
      }

      // Increasing trend - suggest intervention
      if (pattern.isIncreasing && pattern.percentageChange > 30) {
        opportunities.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.recommendation.name,
          title: '📊 Control $categoryName spending',
          description:
              'Your $categoryName spending is trending up (+${pattern.percentageChange.toStringAsFixed(0)}%). '
              'Set a spending limit to prevent further increases',
          priority: InsightPriority.high.name,
          categoryId: categoryId,
          actionable: true,
          metadata: {
            'trend': 'increasing',
            'percentageChange': pattern.percentageChange,
          },
        ));
      }
    }

    return opportunities;
  }

  /// Generate goal achievement recommendations
  List<Insight> generateGoalRecommendations(
    List<SavingsGoal> goals,
    double monthlyIncome,
    double monthlyExpenses,
  ) {
    final recommendations = <Insight>[];
    final monthlySurplus = monthlyIncome - monthlyExpenses;

    for (final goal in goals) {
      final remaining = goal.targetAmount - goal.savedAmount;
      if (remaining <= 0) continue;

      // Calculate months to completion at current savings rate
      final currentMonthlySavings = goal.savedAmount > 0 ? goal.savedAmount / 3 : 0; // Assume 3 months
      final monthsToComplete = currentMonthlySavings > 0 
          ? (remaining / currentMonthlySavings).ceil() 
          : 999;

      // Recommend increased savings if possible
      if (monthlySurplus > 100 && monthsToComplete > 12) {
        final suggestedMonthlySavings = remaining / 6; // Complete in 6 months
        if (suggestedMonthlySavings <= monthlySurplus) {
          recommendations.add(Insight(
            id: const Uuid().v4(),
            type: InsightType.recommendation.name,
            title: '🎯 Accelerate ${goal.name} goal',
            description:
                'You could reach your ${goal.name} goal in 6 months by saving '
                '\$${suggestedMonthlySavings.toStringAsFixed(2)}/month (you have \$${monthlySurplus.toStringAsFixed(2)} surplus)',
            priority: InsightPriority.medium.name,
            actionable: true,
            metadata: {
              'goalId': goal.id,
              'remaining': remaining,
              'suggestedMonthlySavings': suggestedMonthlySavings,
              'monthsToComplete': 6,
            },
          ));
        }
      }

      // Warn if goal is unrealistic
      if (monthsToComplete > 24 && currentMonthlySavings > 0) {
        recommendations.add(Insight(
          id: const Uuid().v4(),
          type: InsightType.warning.name,
          title: '⏰ ${goal.name} goal needs attention',
          description:
              'At current rate, you\'ll reach your ${goal.name} goal in $monthsToComplete months. '
              'Consider increasing monthly savings or adjusting the target',
          priority: InsightPriority.low.name,
          actionable: true,
          metadata: {
            'goalId': goal.id,
            'monthsToComplete': monthsToComplete,
            'currentMonthlySavings': currentMonthlySavings,
          },
        ));
      }
    }

    return recommendations;
  }

  /// Detect potential duplicate subscriptions
  List<Insight> detectDuplicateSubscriptions(
    List<Transaction> transactions,
    Map<String, String> categoryNames,
  ) {
    final insights = <Insight>[];
    
    // Group transactions by similar amounts and category
    final Map<String, List<Transaction>> groupedByCategory = {};
    
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) continue;
      
      groupedByCategory.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }

    for (final entry in groupedByCategory.entries) {
      final categoryId = entry.key;
      final categoryTransactions = entry.value;
      final categoryName = categoryNames[categoryId] ?? 'Unknown';

      // Find transactions with similar amounts (within 5%)
      final Map<double, List<Transaction>> similarAmounts = {};
      
      for (final transaction in categoryTransactions) {
        final roundedAmount = (transaction.amount / 5).round() * 5.0; // Round to nearest $5
        similarAmounts.putIfAbsent(roundedAmount, () => []).add(transaction);
      }

      for (final amountGroup in similarAmounts.values) {
        if (amountGroup.length >= 3) {
          // Potential recurring subscription
          insights.add(Insight(
            id: const Uuid().v4(),
            type: InsightType.recommendation.name,
            title: '🔁 Potential recurring $categoryName expense',
            description:
                'You have ${amountGroup.length} transactions around \$${amountGroup.first.amount.toStringAsFixed(2)}. '
                'Consider setting this up as a recurring transaction',
            priority: InsightPriority.low.name,
            categoryId: categoryId,
            actionable: true,
            metadata: {
              'amount': amountGroup.first.amount,
              'frequency': amountGroup.length,
            },
          ));
        }
      }
    }

    return insights;
  }

  /// Generate spending reduction tips
  List<Insight> generateSpendingReductionTips(
    Map<String, double> categorySpending,
    Map<String, String> categoryNames,
  ) {
    final tips = <Insight>[];
    
    // Find top 3 spending categories
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = sortedCategories.take(3);

    for (final entry in top3) {
      final categoryId = entry.key;
      final amount = entry.value;
      final categoryName = categoryNames[categoryId] ?? 'Unknown';
      
      // Generic reduction tip
      final potentialSavings = amount * 0.15; // 15% reduction
      
      tips.add(Insight(
        id: const Uuid().v4(),
        type: InsightType.recommendation.name,
        title: '💸 Reduce $categoryName spending',
        description:
            '$categoryName is your #${top3.toList().indexOf(entry) + 1} expense category (\$${amount.toStringAsFixed(2)}). '
            'A 15% reduction could save \$${potentialSavings.toStringAsFixed(2)}/month',
        priority: InsightPriority.low.name,
        categoryId: categoryId,
        actionable: true,
        metadata: {
          'currentSpending': amount,
          'potentialSavings': potentialSavings,
          'rank': top3.toList().indexOf(entry) + 1,
        },
      ));
    }

    return tips;
  }
}
