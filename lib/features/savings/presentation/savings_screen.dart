import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../accounts/presentation/accounts_provider.dart';
import '../../accounts/domain/account.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import 'savings_provider.dart';
import 'widgets/savings_goal_card.dart';
import '../../../core/widgets/empty_state_widget.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  void _showContributeDialog(BuildContext context, WidgetRef ref, dynamic goal, List<Account> accounts) {
    final controller = TextEditingController();
    Account? selectedAccount = accounts.isNotEmpty ? accounts.first : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Savings to ${goal.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: \$${goal.savedAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount to Add',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              if (accounts.isNotEmpty)
                DropdownButtonFormField<Account>(
                  value: selectedAccount,
                  decoration: const InputDecoration(
                    labelText: 'Deduct from Account',
                    border: OutlineInputBorder(),
                  ),
                  items: accounts.map((a) => DropdownMenuItem(
                    value: a,
                    child: Text('${a.name} (\$${a.balance.toStringAsFixed(0)})'),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedAccount = val),
                )
              else
                const Text('No accounts available to fund this goal.', style: TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty && selectedAccount != null) {
                  final amount = double.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    if (selectedAccount!.balance < amount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient funds in selected account')),
                      );
                      return;
                    }

                    // 1. Update Goal
                    final newAmount = goal.savedAmount + amount;
                    final updatedGoal = goal.copyWith(savedAmount: newAmount);
                    ref.read(savingsProvider.notifier).updateGoal(updatedGoal);

                    // 2. Deduct from Account
                    final updatedAccount = selectedAccount!.copyWith(balance: selectedAccount!.balance - amount);
                    ref.read(accountsProvider.notifier).updateAccount(updatedAccount);

                    // 3. Create Transaction
                    final tx = Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amount,
                      type: TransactionType.expense, 
                      categoryId: 'savings', // Lowercase ID usually preferred or specific ID
                      currencyCode: selectedAccount!.currencyCode,
                      date: DateTime.now(),
                      accountId: selectedAccount!.id,
                      note: 'Saved for ${goal.name}',
                    );
                    ref.read(transactionsProvider.notifier).addTransaction(tx);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added \$$amount to ${goal.name}')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
      ),
      body: goals.isEmpty
          ? EmptyStateWidget(
              icon: Icons.savings_outlined,
              title: 'No Savings Goals',
              description: 'Start building your future by creating your first savings goal.',
              actionLabel: 'Create Goal',
              onActionPressed: () => context.push('/add-savings-goal'),
              color: Colors.green.shade600,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return SavingsGoalCard(
                  goal: goals[index],
                  onTap: () {
                    _showContributeDialog(context, ref, goals[index], accounts);
                  },
                  onEdit: () {
                    context.push('/add-savings-goal', extra: goals[index]);
                  },
                  onReset: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Savings?'),
                        content: Text('Are you sure you want to reset progress for "${goals[index].name}" to \$0?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              ref.read(savingsProvider.notifier).updateGoal(goals[index].copyWith(savedAmount: 0));
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Goal?'),
                        content: Text('Are you sure you want to delete "${goals[index].name}"? This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () {
                              ref.read(savingsProvider.notifier).deleteGoal(goals[index].id);
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ).animate()
                 .fadeIn(duration: 600.ms, delay: (100 * index).ms)
                 .slideY(begin: 0.1, end: 0);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-savings-goal'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
