import 'package:hive/hive.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 3)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final double savedAmount;

  @HiveField(4)
  final String currencyCode;

  @HiveField(5)
  final DateTime? deadline;

  @HiveField(6)
  final int colorValue;

  @HiveField(7)
  final int iconCode;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.currencyCode,
    this.deadline,
    required this.colorValue,
    required this.iconCode,
  });
  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? currencyCode,
    DateTime? deadline,
    int? colorValue,
    int? iconCode,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      deadline: deadline ?? this.deadline,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
    );
  }
}
