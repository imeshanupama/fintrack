import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../../../core/data/hive_repository.dart';
import '../domain/savings_goal.dart';

class SavingsRepository extends HiveRepository<SavingsGoal> {
  SavingsRepository(Box<SavingsGoal> box) : super(box);
}

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  final box = Hive.box<SavingsGoal>(BoxNames.savings);
  return SavingsRepository(box);
});
