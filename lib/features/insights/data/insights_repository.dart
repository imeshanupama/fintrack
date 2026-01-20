import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../domain/insight.dart';

final insightsRepositoryProvider = Provider((ref) => InsightsRepository());

class InsightsRepository {
  Box<Insight> get _box => Hive.box<Insight>(BoxNames.insightsBox);

  // Create
  Future<void> saveInsight(Insight insight) async {
    await _box.put(insight.id, insight);
  }

  Future<void> saveInsights(List<Insight> insights) async {
    for (final insight in insights) {
      await _box.put(insight.id, insight);
    }
  }

  // Read
  Insight? getInsight(String id) {
    return _box.get(id);
  }

  List<Insight> getAllInsights() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  List<Insight> getActiveInsights() {
    return _box.values
        .where((insight) => insight.isActive)
        .toList()
      ..sort((a, b) {
        // Sort by priority first, then by date
        final priorityOrder = {
          'critical': 0,
          'high': 1,
          'medium': 2,
          'low': 3,
        };
        final aPriority = priorityOrder[a.priority] ?? 4;
        final bPriority = priorityOrder[b.priority] ?? 4;
        
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  List<Insight> getInsightsByType(InsightType type) {
    return _box.values
        .where((insight) => insight.type == type.name && insight.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Insight> getInsightsByCategory(String categoryId) {
    return _box.values
        .where((insight) => insight.categoryId == categoryId && insight.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Insight> getInsightHistory() {
    return _box.values
        .where((insight) => insight.isDismissed)
        .toList()
      ..sort((a, b) => b.dismissedAt!.compareTo(a.dismissedAt!));
  }

  // Update
  Future<void> dismissInsight(String id) async {
    final insight = _box.get(id);
    if (insight != null) {
      final dismissed = insight.dismiss();
      await _box.put(id, dismissed);
    }
  }

  Future<void> updateInsight(Insight insight) async {
    await _box.put(insight.id, insight);
  }

  // Delete
  Future<void> deleteInsight(String id) async {
    await _box.delete(id);
  }

  Future<void> clearOldInsights({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final oldInsights = _box.values
        .where((insight) => insight.createdAt.isBefore(cutoffDate))
        .toList();

    for (final insight in oldInsights) {
      await _box.delete(insight.id);
    }
  }

  // Stream for real-time updates
  Stream<List<Insight>> watchActiveInsights() {
    return _box.watch().map((_) => getActiveInsights());
  }
}
