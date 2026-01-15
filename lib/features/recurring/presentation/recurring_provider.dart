import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../recurring/domain/recurring_transaction.dart';
import '../../recurring/data/recurring_transaction_repository.dart';

final recurringTransactionsProvider = NotifierProvider<RecurringTransactionsNotifier, List<RecurringTransaction>>(RecurringTransactionsNotifier.new);

class RecurringTransactionsNotifier extends Notifier<List<RecurringTransaction>> {
  late RecurringTransactionRepository _repository;

  @override
  List<RecurringTransaction> build() {
    _repository = ref.watch(recurringTransactionRepositoryProvider);
    return _repository.getAll();
  }

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    await _repository.add(transaction.id, transaction);
    state = _repository.getAll();
  }

  Future<void> updateRecurringTransaction(RecurringTransaction transaction) async {
    await _repository.update(transaction.id, transaction);
    state = _repository.getAll();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }
}
