import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 6) // Using next available typeId, need to confirm 6 is free, likely is based on previous main.dart view
class Debt extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String personName;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final DateTime? dueDate;

  @HiveField(5)
  final bool isLent; // true if I lent money (Assets), false if I borrowed (Liabilities)

  @HiveField(6)
  final bool isSettled;

  @HiveField(7)
  final String? description;

  Debt({
    required this.id,
    required this.personName,
    required this.amount,
    required this.date,
    this.dueDate,
    required this.isLent,
    this.isSettled = false,
    this.description,
  });

  Debt copyWith({
    String? id,
    String? personName,
    double? amount,
    DateTime? date,
    DateTime? dueDate,
    bool? isLent,
    bool? isSettled,
    String? description,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      isLent: isLent ?? this.isLent,
      isSettled: isSettled ?? this.isSettled,
      description: description ?? this.description,
    );
  }
}
