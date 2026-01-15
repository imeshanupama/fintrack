import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'recurring_provider.dart';
import '../../recurring/domain/recurring_transaction.dart';
import '../../transactions/domain/transaction_type.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringList = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Recurring Transactions', style: GoogleFonts.outfit()),
      ),
      body: recurringList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.repeat, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('No recurring transactions', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recurringList.length,
              itemBuilder: (context, index) {
                final recurring = recurringList[index];
                return Dismissible(
                  key: Key(recurring.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete?'),
                        content: const Text('Stop this recurring transaction?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    ref.read(recurringTransactionsProvider.notifier).deleteRecurringTransaction(recurring.id);
                  },
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: recurring.type == TransactionType.income ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        child: Icon(
                          recurring.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                          color: recurring.type == TransactionType.income ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(recurring.note, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text('${recurring.interval} • Next: ${DateFormat('MMM d').format(recurring.nextDueDate)}'),
                      trailing: Text(
                        '${recurring.currencyCode} ${recurring.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: recurring.type == TransactionType.income ? Colors.green : Colors.red,
                        ),
                      ),
                      onTap: () {
                         context.push('/add-recurring', extra: recurring);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-recurring'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
