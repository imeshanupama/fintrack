import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/debt_repository.dart';
import '../domain/debt.dart';

// Sort order enum
enum DebtSortOrder {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}

// Filter enum
enum DebtFilter {
  all,
  active,
  settled
}

class DebtState {
  final List<Debt> debts;
  final DebtSortOrder sortOrder;
  final DebtFilter filter;

  DebtState({
    required this.debts, 
    this.sortOrder = DebtSortOrder.dateDesc,
    this.filter = DebtFilter.active
  });
  
  DebtState copyWith({
    List<Debt>? debts,
    DebtSortOrder? sortOrder,
    DebtFilter? filter,
  }) {
    return DebtState(
      debts: debts ?? this.debts,
      sortOrder: sortOrder ?? this.sortOrder,
      filter: filter ?? this.filter,
    );
  }

  List<Debt> get filteredDebts {
    var filtered = debts;
    if (filter == DebtFilter.active) {
      filtered = filtered.where((d) => !d.isSettled).toList();
    } else if (filter == DebtFilter.settled) {
      filtered = filtered.where((d) => d.isSettled).toList();
    }
    
    // Sort
    final sorted = List<Debt>.from(filtered);
    switch (sortOrder) {
      case DebtSortOrder.dateDesc:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case DebtSortOrder.dateAsc:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case DebtSortOrder.amountDesc:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case DebtSortOrder.amountAsc:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return sorted;
  }
  
  double get totalLent => debts
    .where((d) => d.isLent && !d.isSettled)
    .fold(0.0, (sum, d) => sum + d.amount);
    
  double get totalBorrowed => debts
    .where((d) => !d.isLent && !d.isSettled)
    .fold(0.0, (sum, d) => sum + d.amount);
}

final debtProvider = NotifierProvider<DebtNotifier, DebtState>(DebtNotifier.new);

class DebtNotifier extends Notifier<DebtState> {
  late DebtRepository _repository;

  @override
  DebtState build() {
    _repository = ref.watch(debtRepositoryProvider);
    return DebtState(debts: _repository.getDebts());
  }

  void refresh() {
    state = state.copyWith(debts: _repository.getDebts());
  }

  Future<void> addDebt(Debt debt) async {
    await _repository.addDebt(debt);
    refresh();
  }

  Future<void> updateDebt(Debt debt) async {
    await _repository.updateDebt(debt);
    refresh();
  }

  Future<void> deleteDebt(String id) async {
    await _repository.deleteDebt(id);
    refresh();
  }

  Future<void> settleDebt(String id) async {
    await _repository.settleDebt(id);
    refresh();
  }
  
  void setFilter(DebtFilter filter) {
    state = state.copyWith(filter: filter);
  }
  
  void setSortOrder(DebtSortOrder order) {
    state = state.copyWith(sortOrder: order);
  }
}
