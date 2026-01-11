import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 4)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String period; // 'Monthly', 'Weekly'

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
  });
}
