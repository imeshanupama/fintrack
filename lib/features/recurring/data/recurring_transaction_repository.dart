import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../../../core/data/hive_repository.dart';
import '../domain/recurring_transaction.dart';

final recurringTransactionRepositoryProvider = Provider<RecurringTransactionRepository>((ref) {
  return RecurringTransactionRepository();
});

class RecurringTransactionRepository extends HiveRepository<RecurringTransaction> {
  RecurringTransactionRepository() : super(Hive.box<RecurringTransaction>(BoxNames.recurringBox));
}
