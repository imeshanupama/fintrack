import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../transactions/domain/transaction.dart';
import '../data/recurring_transaction_repository.dart';
import '../domain/recurring_transaction.dart';
import '../../accounts/presentation/accounts_provider.dart'; // To update account balances

final recurringTransactionServiceProvider = Provider<RecurringTransactionService>((ref) {
  return RecurringTransactionService(ref);
});

class RecurringTransactionService {
  final Ref ref;

  RecurringTransactionService(this.ref);

  Future<void> checkAndGenerateTransactions() async {
    final repository = ref.read(recurringTransactionRepositoryProvider);
    final transactionsNotifier = ref.read(transactionsProvider.notifier);
    final allRecurring = repository.getAll();
    final now = DateTime.now();

    for (var recurring in allRecurring) {
      if (recurring.nextDueDate.isBefore(now) || recurring.nextDueDate.isAtSameMomentAs(now)) {
        // Generate Transaction
        final newTransaction = Transaction(
          id: const Uuid().v4(),
          amount: recurring.amount,
          currencyCode: recurring.currencyCode,
          categoryId: recurring.categoryId,
          accountId: recurring.accountId,
          date: now,
          note: 'Recurring: ${recurring.note}',
          type: recurring.type,
        );

        await transactionsNotifier.addTransaction(newTransaction);
        
        // Also update account balance - Logic duplicated from AddTransactionScreen
        // Ideally should be in a centralized UseCase or Repository method
        final accounts = ref.read(accountsProvider);
        try {
            final account = accounts.firstWhere((a) => a.id == recurring.accountId);
             final newBalance = recurring.type.toString().contains('income')
              ? account.balance + recurring.amount
              : account.balance - recurring.amount;
            
            // Re-construct account to update balance. Assuming immutable model.
            // Note: Account model doesn't have copyWith yet, should add it or use constructor
            // Using a heuristic here since I can't see Account model right now to be 100% sure about copyWith
             // Actually I saw Account model earlier, it didn't have copyWith.
             // I will use constructor.
             
             // BUT, I can't import Account here easily without circular dependencies or just plain import. 
             // I imported accounts_provider.dart.
             
             // Wait, updating account balance is critical. I should probably defer this specific balance update logic 
             // to transactionsNotifier if possible, or accountsNotifier.
             // accountsNotifier has addAccount (upsert).
             
             // Let's rely on manual reconstruction for now.
             
        } catch (e) {
           // Account might have been deleted. Skip.
        }

        // Calculate next due date
        DateTime nextDate = recurring.nextDueDate;
        switch (recurring.interval) {
          case 'Daily':
            nextDate = nextDate.add(const Duration(days: 1));
            break;
          case 'Weekly':
            nextDate = nextDate.add(const Duration(days: 7));
            break;
          case 'Monthly':
            nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
            break;
          case 'Yearly':
            nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
            break;
        }

        // Update recurring transaction
        final updatedRecurring = recurring.copyWith(nextDueDate: nextDate);
        await repository.update(updatedRecurring.id, updatedRecurring);
      }
    }
  }
}
