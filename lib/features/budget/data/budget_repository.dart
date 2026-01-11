import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../../../core/data/hive_repository.dart';
import '../domain/budget.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

class BudgetRepository extends HiveRepository<Budget> {
  BudgetRepository() : super(Hive.box<Budget>(BoxNames.budgetBox));
}
