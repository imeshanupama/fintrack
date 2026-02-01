import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/categorization_rule.dart';

final categorizationRepositoryProvider = Provider<CategorizationRepository>((ref) {
  return CategorizationRepository();
});

class CategorizationRepository {
  static const String _boxName = 'categorization_rules';
  Box<CategorizationRule>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<CategorizationRule>(_boxName);
    } else {
      _box = Hive.box<CategorizationRule>(_boxName);
    }
  }

  Box<CategorizationRule> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('CategorizationRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Get all categorization rules
  List<CategorizationRule> getAll() {
    return box.values.toList();
  }

  /// Get a specific rule by ID
  CategorizationRule? getById(String id) {
    return box.get(id);
  }

  /// Find rules matching a pattern (case-insensitive)
  List<CategorizationRule> findByPattern(String pattern) {
    final lowerPattern = pattern.toLowerCase();
    return box.values
        .where((rule) => rule.pattern.toLowerCase().contains(lowerPattern))
        .toList();
  }

  /// Get rules for a specific category
  List<CategorizationRule> getByCategoryId(String categoryId) {
    return box.values
        .where((rule) => rule.categoryId == categoryId)
        .toList();
  }

  /// Get user-defined rules only
  List<CategorizationRule> getUserDefinedRules() {
    return box.values
        .where((rule) => rule.isUserDefined)
        .toList();
  }

  /// Add a new rule
  Future<void> add(String id, CategorizationRule rule) async {
    await box.put(id, rule);
  }

  /// Update an existing rule
  Future<void> update(String id, CategorizationRule rule) async {
    await box.put(id, rule);
  }

  /// Delete a rule
  Future<void> delete(String id) async {
    await box.delete(id);
  }

  /// Increment usage count and update last used time
  Future<void> recordUsage(String id) async {
    final rule = box.get(id);
    if (rule != null) {
      final updated = rule.copyWith(
        usageCount: rule.usageCount + 1,
        lastUsedAt: DateTime.now(),
      );
      await box.put(id, updated);
    }
  }

  /// Update confidence score for a rule
  Future<void> updateConfidence(String id, double newConfidence) async {
    final rule = box.get(id);
    if (rule != null) {
      final updated = rule.copyWith(confidence: newConfidence);
      await box.put(id, updated);
    }
  }

  /// Clear all rules
  Future<void> clear() async {
    await box.clear();
  }

  /// Get most frequently used rules
  List<CategorizationRule> getMostUsed({int limit = 10}) {
    final rules = box.values.toList();
    rules.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return rules.take(limit).toList();
  }

  /// Get highest confidence rules
  List<CategorizationRule> getHighestConfidence({int limit = 10}) {
    final rules = box.values.toList();
    rules.sort((a, b) => b.confidence.compareTo(a.confidence));
    return rules.take(limit).toList();
  }
}
