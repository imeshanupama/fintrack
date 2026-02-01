import 'package:hive/hive.dart';

part 'categorization_rule.g.dart';

@HiveType(typeId: 13)
class CategorizationRule extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String pattern; // Merchant name or keyword pattern

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final double confidence; // 0.0 to 1.0

  @HiveField(4)
  final int usageCount; // How many times this rule has been applied

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastUsedAt;

  @HiveField(7)
  final bool isUserDefined; // true if user created/confirmed this rule

  CategorizationRule({
    required this.id,
    required this.pattern,
    required this.categoryId,
    required this.confidence,
    this.usageCount = 0,
    required this.createdAt,
    required this.lastUsedAt,
    this.isUserDefined = false,
  });

  CategorizationRule copyWith({
    String? id,
    String? pattern,
    String? categoryId,
    double? confidence,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isUserDefined,
  }) {
    return CategorizationRule(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      categoryId: categoryId ?? this.categoryId,
      confidence: confidence ?? this.confidence,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isUserDefined: isUserDefined ?? this.isUserDefined,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pattern': pattern,
      'categoryId': categoryId,
      'confidence': confidence,
      'usageCount': usageCount,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'isUserDefined': isUserDefined,
    };
  }

  factory CategorizationRule.fromJson(Map<String, dynamic> json) {
    return CategorizationRule(
      id: json['id'] as String,
      pattern: json['pattern'] as String,
      categoryId: json['categoryId'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      usageCount: json['usageCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      isUserDefined: json['isUserDefined'] as bool,
    );
  }
}
