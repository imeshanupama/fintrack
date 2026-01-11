import 'package:hive/hive.dart';
import '../../transactions/domain/transaction_type.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 5)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String currencyCode;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final String accountId;

  @HiveField(5)
  final String note;

  @HiveField(6)
  final TransactionType type;

  @HiveField(7)
  final String interval; // 'Daily', 'Weekly', 'Monthly', 'Yearly'

  @HiveField(8)
  final DateTime nextDueDate;

  RecurringTransaction({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.categoryId,
    required this.accountId,
    required this.note,
    required this.type,
    required this.interval,
    required this.nextDueDate,
  });

  RecurringTransaction copyWith({
    String? id,
    double? amount,
    String? currencyCode,
    String? categoryId,
    String? accountId,
    String? note,
    TransactionType? type,
    String? interval,
    DateTime? nextDueDate,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'accountId': accountId,
      'note': note,
      'type': type.name,
      'interval': interval,
      'nextDueDate': nextDueDate.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String,
      note: json['note'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      interval: json['interval'] as String,
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
    );
  }
}
