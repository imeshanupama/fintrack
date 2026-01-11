import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';

final budgetProvider = NotifierProvider<BudgetNotifier, List<Budget>>(BudgetNotifier.new);

class BudgetNotifier extends Notifier<List<Budget>> {
  late BudgetRepository _repository;

  @override
  List<Budget> build() {
    _repository = ref.watch(budgetRepositoryProvider);
    return _repository.getAll();
  }

  void loadBudgets() {
    state = _repository.getAll();
  }

  Future<void> addBudget(Budget budget) async {
    await _repository.add(budget.id, budget);
    loadBudgets();
  }

  Future<void> updateBudget(Budget budget) async {
    await _repository.update(budget.id, budget);
    loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _repository.delete(id);
    loadBudgets();
  }
}

