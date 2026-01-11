import 'package:hive/hive.dart';
import '../../transactions/domain/transaction_type.dart';

part 'transaction.g.dart';

@HiveType(typeId: 2)
class Transaction extends HiveObject {
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
  final DateTime date;

  @HiveField(6)
  final String note;

  @HiveField(7)
  final TransactionType type;

  Transaction({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.categoryId,
    required this.accountId,
    required this.date,
    required this.note,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'accountId': accountId,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.name,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String,
      type: TransactionType.values.byName(json['type'] as String),
    );
  }
}
