import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/box_names.dart';
import '../domain/debt.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) => DebtRepository());

class DebtRepository {
  Box<Debt> get _box => Hive.box<Debt>(BoxNames.debtsBox);

  Future<void> addDebt(Debt debt) async {
    await _box.put(debt.id, debt);
  }

  Future<void> updateDebt(Debt debt) async {
    await _box.put(debt.id, debt);
  }

  Future<void> deleteDebt(String id) async {
    await _box.delete(id);
  }

  List<Debt> getDebts() {
    return _box.values.toList();
  }

  // Stream for reactive UI updates
  Stream<List<Debt>> getDebtsStream() {
    return _box.watch().map((event) => _box.values.toList());
  }

  Future<void> settleDebt(String id) async {
    final debt = _box.get(id);
    if (debt != null) {
      final updatedDebt = debt.copyWith(isSettled: true);
      await _box.put(id, updatedDebt);
    }
  }
}
