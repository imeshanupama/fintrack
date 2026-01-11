import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/account_repository.dart';
import '../domain/account.dart';

final accountsProvider = NotifierProvider<AccountsNotifier, List<Account>>(AccountsNotifier.new);

class AccountsNotifier extends Notifier<List<Account>> {
  late AccountRepository _repository;

  @override
  List<Account> build() {
    _repository = ref.watch(accountRepositoryProvider);
    return _repository.getAll();
  }

  void loadAccounts() {
    state = _repository.getAll();
  }

  Future<void> addAccount(Account account) async {
    await _repository.add(account.id, account);
    loadAccounts();
  }
  Future<void> updateAccount(Account account) async {
    await _repository.update(account.id, account);
    loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _repository.delete(id);
    loadAccounts();
  }
}
