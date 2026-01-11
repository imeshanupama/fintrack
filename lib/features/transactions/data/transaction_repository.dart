import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../../../core/data/hive_repository.dart';
import '../domain/transaction.dart';

class TransactionRepository extends HiveRepository<Transaction> {
  TransactionRepository(Box<Transaction> box) : super(box);

  List<Transaction> getTransactionsForAccount(String accountId) {
    return box.values.where((t) => t.accountId == accountId).toList();
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final box = Hive.box<Transaction>(BoxNames.transactions);
  return TransactionRepository(box);
});
