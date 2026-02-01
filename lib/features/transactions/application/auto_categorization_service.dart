import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/categorization_rule.dart';
import '../domain/category_suggestion.dart';
import '../data/categorization_repository.dart';
import '../domain/transaction.dart';
import '../../categories/domain/category.dart';

final autoCategorizationServiceProvider = Provider<AutoCategorizationService>((ref) {
  final repository = ref.watch(categorizationRepositoryProvider);
  return AutoCategorizationService(repository);
});

class AutoCategorizationService {
  final CategorizationRepository _repository;
  final _uuid = const Uuid();

  // Built-in merchant patterns for common merchants
  static final Map<String, List<String>> _builtInPatterns = {
    // Food & Dining
    'starbucks': ['coffee', 'cafe', 'dining'],
    'mcdonalds': ['fast food', 'dining'],
    'subway': ['fast food', 'dining'],
    'pizza hut': ['dining', 'restaurant'],
    'dominos': ['dining', 'pizza'],
    'kfc': ['fast food', 'dining'],
    'burger king': ['fast food', 'dining'],
    
    // Groceries
    'walmart': ['groceries', 'shopping'],
    'target': ['groceries', 'shopping'],
    'whole foods': ['groceries', 'organic'],
    'trader joe': ['groceries'],
    'costco': ['groceries', 'wholesale'],
    'safeway': ['groceries'],
    'kroger': ['groceries'],
    
    // Transportation
    'uber': ['transportation', 'ride'],
    'lyft': ['transportation', 'ride'],
    'shell': ['gas', 'fuel', 'transportation'],
    'chevron': ['gas', 'fuel', 'transportation'],
    'exxon': ['gas', 'fuel', 'transportation'],
    'bp': ['gas', 'fuel', 'transportation'],
    
    // Entertainment
    'netflix': ['entertainment', 'streaming', 'subscription'],
    'spotify': ['entertainment', 'music', 'subscription'],
    'amazon prime': ['entertainment', 'subscription'],
    'hulu': ['entertainment', 'streaming', 'subscription'],
    'disney': ['entertainment', 'streaming', 'subscription'],
    'hbo': ['entertainment', 'streaming', 'subscription'],
    'cinema': ['entertainment', 'movies'],
    'theater': ['entertainment', 'movies'],
    
    // Shopping
    'amazon': ['shopping', 'online'],
    'ebay': ['shopping', 'online'],
    'etsy': ['shopping', 'online'],
    'best buy': ['electronics', 'shopping'],
    'apple store': ['electronics', 'shopping'],
    
    // Health & Fitness
    'gym': ['fitness', 'health'],
    'pharmacy': ['health', 'medical'],
    'cvs': ['pharmacy', 'health'],
    'walgreens': ['pharmacy', 'health'],
    'hospital': ['health', 'medical'],
    'clinic': ['health', 'medical'],
    
    // Utilities
    'electric': ['utilities', 'bills'],
    'water': ['utilities', 'bills'],
    'internet': ['utilities', 'bills'],
    'phone': ['utilities', 'bills'],
    'verizon': ['utilities', 'phone'],
    'at&t': ['utilities', 'phone'],
    't-mobile': ['utilities', 'phone'],
  };

  AutoCategorizationService(this._repository);

  /// Initialize the service and load built-in patterns if needed
  Future<void> initialize() async {
    await _repository.init();
    // Built-in patterns are used for matching but not stored
    // Only user-confirmed patterns are stored
  }

  /// Suggest a category for a transaction based on note/description
  Future<CategorySuggestion?> suggestCategory({
    required String note,
    required double amount,
    required List<Category> availableCategories,
    List<Transaction>? historicalTransactions,
  }) async {
    if (note.trim().isEmpty) return null;

    final noteLower = note.toLowerCase();
    
    // 1. First, check user-defined rules (highest priority)
    final userRules = _repository.getUserDefinedRules();
    for (final rule in userRules) {
      if (noteLower.contains(rule.pattern.toLowerCase())) {
        // Check if category still exists
        final categoryExists = availableCategories.any((c) => c.id == rule.categoryId);
        if (categoryExists) {
          await _repository.recordUsage(rule.id);
          return CategorySuggestion(
            categoryId: rule.categoryId,
            confidence: rule.confidence,
            reason: 'Based on your previous choices',
            matchedPattern: rule.pattern,
          );
        }
      }
    }

    // 2. Check built-in patterns
    for (final entry in _builtInPatterns.entries) {
      if (noteLower.contains(entry.key)) {
        // Try to match keywords to available categories
        final matchedCategory = _findCategoryByKeywords(
          entry.value,
          availableCategories,
        );
        
        if (matchedCategory != null) {
          return CategorySuggestion(
            categoryId: matchedCategory.id,
            confidence: 0.75, // Built-in patterns have good confidence
            reason: 'Common merchant pattern',
            matchedPattern: entry.key,
          );
        }
      }
    }

    // 3. Check historical transactions with similar notes
    if (historicalTransactions != null && historicalTransactions.isNotEmpty) {
      final similarTransaction = _findSimilarTransaction(
        note: noteLower,
        amount: amount,
        transactions: historicalTransactions,
      );

      if (similarTransaction != null) {
        final categoryExists = availableCategories.any(
          (c) => c.id == similarTransaction.categoryId,
        );
        
        if (categoryExists) {
          return CategorySuggestion(
            categoryId: similarTransaction.categoryId,
            confidence: 0.65,
            reason: 'Similar to previous transaction',
            matchedPattern: null,
          );
        }
      }
    }

    // 4. Fallback: Most used category for similar amounts
    if (historicalTransactions != null && historicalTransactions.isNotEmpty) {
      final categoryId = _getMostUsedCategoryForAmount(
        amount: amount,
        transactions: historicalTransactions,
        tolerance: 0.2, // 20% tolerance
      );

      if (categoryId != null) {
        final categoryExists = availableCategories.any((c) => c.id == categoryId);
        if (categoryExists) {
          return CategorySuggestion(
            categoryId: categoryId,
            confidence: 0.55,
            reason: 'Common amount for this category',
            matchedPattern: null,
          );
        }
      }
    }

    return null;
  }

  /// Learn from user's category selection
  Future<void> learnFromSelection({
    required String note,
    required String selectedCategoryId,
    String? suggestedCategoryId,
  }) async {
    if (note.trim().isEmpty) return;

    final noteLower = note.toLowerCase();
    
    // Extract potential merchant name (first few words)
    final words = noteLower.split(RegExp(r'\s+'));
    final pattern = words.take(3).join(' ').trim();
    
    if (pattern.isEmpty) return;

    // Check if we already have a rule for this pattern
    final existingRules = _repository.findByPattern(pattern);
    
    if (existingRules.isNotEmpty) {
      // Update existing rule
      final rule = existingRules.first;
      
      if (rule.categoryId == selectedCategoryId) {
        // User confirmed our suggestion - increase confidence
        final newConfidence = (rule.confidence + 0.1).clamp(0.0, 1.0);
        await _repository.updateConfidence(rule.id, newConfidence);
        await _repository.recordUsage(rule.id);
      } else {
        // User chose different category - decrease confidence or update
        if (rule.confidence > 0.7) {
          // High confidence but wrong - reduce it
          await _repository.updateConfidence(rule.id, rule.confidence - 0.2);
        } else {
          // Low confidence - replace with new category
          final updated = rule.copyWith(
            categoryId: selectedCategoryId,
            confidence: 0.6,
            isUserDefined: true,
          );
          await _repository.update(rule.id, updated);
        }
      }
    } else {
      // Create new rule
      final newRule = CategorizationRule(
        id: _uuid.v4(),
        pattern: pattern,
        categoryId: selectedCategoryId,
        confidence: suggestedCategoryId == selectedCategoryId ? 0.8 : 0.7,
        usageCount: 1,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        isUserDefined: true,
      );
      
      await _repository.add(newRule.id, newRule);
    }
  }

  /// Find category by matching keywords to category names
  Category? _findCategoryByKeywords(
    List<String> keywords,
    List<Category> categories,
  ) {
    for (final keyword in keywords) {
      final match = categories.firstWhere(
        (cat) => cat.name.toLowerCase().contains(keyword),
        orElse: () => categories.firstWhere(
          (cat) => keyword.contains(cat.name.toLowerCase()),
          orElse: () => categories.first, // This won't be used due to the outer check
        ),
      );
      
      // Check if we actually found a match
      if (match.name.toLowerCase().contains(keyword) ||
          keyword.contains(match.name.toLowerCase())) {
        return match;
      }
    }
    return null;
  }

  /// Find similar transaction based on note similarity
  Transaction? _findSimilarTransaction({
    required String note,
    required double amount,
    required List<Transaction> transactions,
  }) {
    if (transactions.isEmpty) return null;

    // Calculate similarity scores
    final scored = transactions.map((t) {
      final similarity = _calculateSimilarity(note, t.note.toLowerCase());
      return MapEntry(t, similarity);
    }).where((entry) => entry.value > 0.6) // At least 60% similar
        .toList();

    if (scored.isEmpty) return null;

    // Sort by similarity
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.first.key;
  }

  /// Simple similarity calculation (Jaccard similarity on words)
  double _calculateSimilarity(String text1, String text2) {
    final words1 = text1.split(RegExp(r'\s+')).toSet();
    final words2 = text2.split(RegExp(r'\s+')).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return intersection / union;
  }

  /// Get most used category for similar amounts
  String? _getMostUsedCategoryForAmount({
    required double amount,
    required List<Transaction> transactions,
    double tolerance = 0.2,
  }) {
    final minAmount = amount * (1 - tolerance);
    final maxAmount = amount * (1 + tolerance);

    final similarTransactions = transactions.where(
      (t) => t.amount >= minAmount && t.amount <= maxAmount,
    ).toList();

    if (similarTransactions.isEmpty) return null;

    // Count category occurrences
    final categoryCount = <String, int>{};
    for (final t in similarTransactions) {
      categoryCount[t.categoryId] = (categoryCount[t.categoryId] ?? 0) + 1;
    }

    // Find most common
    var maxCount = 0;
    String? mostUsedCategory;
    
    categoryCount.forEach((categoryId, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsedCategory = categoryId;
      }
    });

    return mostUsedCategory;
  }

  /// Get statistics about learned patterns
  Future<Map<String, dynamic>> getStatistics() async {
    final allRules = _repository.getAll();
    final userRules = _repository.getUserDefinedRules();
    final mostUsed = _repository.getMostUsed(limit: 5);

    return {
      'totalRules': allRules.length,
      'userDefinedRules': userRules.length,
      'averageConfidence': allRules.isEmpty
          ? 0.0
          : allRules.map((r) => r.confidence).reduce((a, b) => a + b) / allRules.length,
      'mostUsedRules': mostUsed.map((r) => {
        'pattern': r.pattern,
        'usageCount': r.usageCount,
        'confidence': r.confidence,
      }).toList(),
    };
  }

  /// Clear all learned patterns
  Future<void> clearAllRules() async {
    await _repository.clear();
  }
}
