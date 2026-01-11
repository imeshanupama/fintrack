import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/savings_repository.dart';
import '../domain/savings_goal.dart';

final savingsProvider = NotifierProvider<SavingsNotifier, List<SavingsGoal>>(SavingsNotifier.new);

class SavingsNotifier extends Notifier<List<SavingsGoal>> {
  late SavingsRepository _repository;

  @override
  List<SavingsGoal> build() {
    _repository = ref.watch(savingsRepositoryProvider);
    return _repository.getAll();
  }

  void loadGoals() {
    state = _repository.getAll();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    await _repository.add(goal.id, goal);
    loadGoals();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await _repository.update(goal.id, goal);
    loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.delete(id);
    loadGoals();
  }
}
