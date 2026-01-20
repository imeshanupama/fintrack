import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bill_split_repository.dart';
import '../domain/bill_split.dart';
import '../domain/split_participant.dart';

// Providers
final billSplitsProvider = StreamProvider<List<BillSplit>>((ref) {
  final repository = ref.watch(billSplitRepositoryProvider);
  return repository.watchAllBillSplits();
});

final activeBillSplitsProvider = StreamProvider<List<BillSplit>>((ref) {
  final repository = ref.watch(billSplitRepositoryProvider);
  return repository.watchActiveSplits();
});

final settledBillSplitsProvider = Provider<List<BillSplit>>((ref) {
  final repository = ref.watch(billSplitRepositoryProvider);
  return repository.getSettledSplits();
});

// Notifier for managing bill splits
final billSplitNotifierProvider = Provider((ref) => BillSplitNotifier(ref));

class BillSplitNotifier {
  final Ref _ref;

  BillSplitNotifier(this._ref);

  BillSplitRepository get _repository => _ref.read(billSplitRepositoryProvider);

  // Create
  Future<void> addBillSplit(BillSplit billSplit) async {
    await _repository.addBillSplit(billSplit);
  }

  // Update
  Future<void> updateBillSplit(BillSplit billSplit) async {
    await _repository.updateBillSplit(billSplit);
  }

  // Delete
  Future<void> deleteBillSplit(String id) async {
    await _repository.deleteBillSplit(id);
  }

  // Settlement Logic
  Future<void> markParticipantAsPaid(String billSplitId, String participantName) async {
    final billSplit = _repository.getBillSplit(billSplitId);
    if (billSplit == null) return;

    final updatedParticipants = billSplit.participants.map((p) {
      if (p.name == participantName) {
        return p.markAsPaid();
      }
      return p;
    }).toList();

    final updatedBillSplit = billSplit.copyWith(participants: updatedParticipants);
    await _repository.updateBillSplit(updatedBillSplit);
  }

  Future<void> markAllParticipantsAsPaid(String billSplitId) async {
    final billSplit = _repository.getBillSplit(billSplitId);
    if (billSplit == null) return;

    final updatedParticipants = billSplit.participants.map((p) => p.markAsPaid()).toList();
    final updatedBillSplit = billSplit.copyWith(participants: updatedParticipants);
    await _repository.updateBillSplit(updatedBillSplit);
  }

  // Search/Filter
  List<BillSplit> searchByPerson(String personName) {
    return _repository.getSplitsByPerson(personName);
  }

  // Get single bill split
  BillSplit? getBillSplit(String id) {
    return _repository.getBillSplit(id);
  }
}
