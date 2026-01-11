import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../presentation/budget_provider.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../settings/presentation/settings_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);
    final transactions = ref.watch(transactionsProvider);
    final currency = ref.watch(settingsProvider).currency;
    String symbol = '\$';
    if (currency == 'EUR') symbol = '€';
    if (currency == 'GBP') symbol = '£';
    if (currency == 'JPY') symbol = '¥';
    if (currency == 'INR') symbol = '₹';
    if (currency == 'LKR') symbol = 'Rs ';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets set',
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => context.push('/add-budget'),
                    child: const Text('Create Budget'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                
                // Calculate spending
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                
                // Filter transactions for this category in current month (assuming monthly for MVP)
                final spent = transactions
                    .where((t) => 
                      t.categoryId == budget.categoryId && 
                      t.type == TransactionType.expense &&
                      t.date.isAfter(startOfMonth)
                    )
                    .fold(0.0, (sum, t) => sum + t.amount);

                final progress = (spent / budget.amount).clamp(0.0, 1.0);
                final isOverBudget = spent > budget.amount;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              budget.categoryId,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOverBudget ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOverBudget ? 'Over Budget' : 'On Track',
                                style: GoogleFonts.outfit(
                                  color: isOverBudget ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  context.push('/add-budget', extra: budget);
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Budget?'),
                                      content: Text('Delete budget for ${budget.categoryId}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                        FilledButton(
                                          onPressed: () {
                                            ref.read(budgetProvider.notifier).deleteBudget(budget.id);
                                            Navigator.pop(context);
                                          },
                                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit Budget')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          color: isOverBudget ? Colors.red : Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: $symbol${spent.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(color: Colors.grey[600]),
                            ),
                            Text(
                              'Target: $symbol${budget.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (100 * index).ms).slideX();
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-budget'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
