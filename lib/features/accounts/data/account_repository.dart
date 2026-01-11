import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../../../core/data/hive_repository.dart';
import '../domain/account.dart';

class AccountRepository extends HiveRepository<Account> {
  AccountRepository(Box<Account> box) : super(box);
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final box = Hive.box<Account>(BoxNames.accounts);
  return AccountRepository(box);
});
