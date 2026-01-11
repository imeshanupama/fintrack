import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<Transaction>>(TransactionsNotifier.new);

class TransactionsNotifier extends Notifier<List<Transaction>> {
  late TransactionRepository _repository;

  @override
  List<Transaction> build() {
    _repository = ref.watch(transactionRepositoryProvider);
    final all = _repository.getAll();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  void loadTransactions() {
    final all = _repository.getAll();
    all.sort((a, b) => b.date.compareTo(a.date));
    state = all;
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _repository.add(transaction.id, transaction);
    loadTransactions(); 
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.update(transaction.id, transaction);
    loadTransactions(); 
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.delete(id);
    loadTransactions(); 
  }
}

