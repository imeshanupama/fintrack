import 'package:hive/hive.dart';

part 'transaction_type.g.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer
}
