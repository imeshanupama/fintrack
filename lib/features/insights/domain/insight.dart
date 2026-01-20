import 'package:hive/hive.dart';

part 'insight.g.dart';

enum InsightType {
  trend,
  warning,
  recommendation,
  prediction,
  achievement,
}

enum InsightPriority {
  low,
  medium,
  high,
  critical,
}

@HiveType(typeId: 11)
class Insight extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // InsightType as string

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String priority; // InsightPriority as string

  @HiveField(5)
  final String? categoryId; // Related category if applicable

  @HiveField(6)
  final bool actionable;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? dismissedAt;

  @HiveField(9)
  final Map<String, dynamic>? metadata; // Additional data (amounts, percentages, etc.)

  Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.categoryId,
    this.actionable = false,
    DateTime? createdAt,
    this.dismissedAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDismissed => dismissedAt != null;
  bool get isActive => !isDismissed;

  InsightType get insightType => InsightType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => InsightType.trend,
      );

  InsightPriority get insightPriority => InsightPriority.values.firstWhere(
        (e) => e.name == priority,
        orElse: () => InsightPriority.low,
      );

  Insight copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? priority,
    String? categoryId,
    bool? actionable,
    DateTime? createdAt,
    DateTime? dismissedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Insight(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      actionable: actionable ?? this.actionable,
      createdAt: createdAt ?? this.createdAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Insight dismiss() {
    return copyWith(dismissedAt: DateTime.now());
  }
}
