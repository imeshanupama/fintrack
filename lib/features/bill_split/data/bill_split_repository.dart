import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../domain/bill_split.dart';

final billSplitRepositoryProvider = Provider((ref) => BillSplitRepository());

class BillSplitRepository {
  Box<BillSplit> get _box => Hive.box<BillSplit>(BoxNames.billSplitsBox);

  // Create
  Future<void> addBillSplit(BillSplit billSplit) async {
    await _box.put(billSplit.id, billSplit);
  }

  // Read
  BillSplit? getBillSplit(String id) {
    return _box.get(id);
  }

  List<BillSplit> getAllBillSplits() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }

  List<BillSplit> getActiveSplits() {
    return _box.values
        .where((split) => !split.isFullySettled)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<BillSplit> getSettledSplits() {
    return _box.values
        .where((split) => split.isFullySettled)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<BillSplit> getSplitsByPerson(String personName) {
    return _box.values
        .where((split) => split.participants.any((p) => 
            p.name.toLowerCase().contains(personName.toLowerCase())))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Update
  Future<void> updateBillSplit(BillSplit billSplit) async {
    await _box.put(billSplit.id, billSplit);
  }

  // Delete
  Future<void> deleteBillSplit(String id) async {
    await _box.delete(id);
  }

  // Stream for real-time updates
  Stream<List<BillSplit>> watchAllBillSplits() {
    return _box.watch().map((_) => getAllBillSplits());
  }

  Stream<List<BillSplit>> watchActiveSplits() {
    return _box.watch().map((_) => getActiveSplits());
  }
}
