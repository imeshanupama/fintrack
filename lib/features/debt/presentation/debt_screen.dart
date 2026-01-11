import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/debt.dart';
import 'debt_provider.dart';

class DebtScreen extends ConsumerWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtState = ref.watch(debtProvider);
    final theme = Theme.of(context);

    // Calculate totals
    final totalLent = debtState.totalLent;
    final totalBorrowed = debtState.totalBorrowed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts & Lending'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-debt'),
        label: const Text('Add Record'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'I Owe',
                    amount: totalBorrowed,
                    color: Colors.redAccent,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Owed to Me',
                    amount: totalLent,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: debtState.filter == DebtFilter.all,
                  onSelected: (_) => ref.read(debtProvider.notifier).setFilter(DebtFilter.all),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Active'),
                  selected: debtState.filter == DebtFilter.active,
                  onSelected: (_) => ref.read(debtProvider.notifier).setFilter(DebtFilter.active),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Settled'),
                  selected: debtState.filter == DebtFilter.settled,
                  onSelected: (_) => ref.read(debtProvider.notifier).setFilter(DebtFilter.settled),
                ),
              ],
            ),
          ),
          
          const Divider(),

          // List
          Expanded(
            child: debtState.filteredDebts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No debts found',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: debtState.filteredDebts.length,
                    itemBuilder: (context, index) {
                      final debt = debtState.filteredDebts[index];
                      return _DebtTile(debt: debt);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.simpleCurrency().format(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtTile extends ConsumerWidget {
  final Debt debt;

  const _DebtTile({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.simpleCurrency();
    final isLent = debt.isLent;
    final color = isLent ? Colors.green : Colors.redAccent;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          isLent ? Icons.arrow_outward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(debt.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        'Due: ${debt.dueDate != null ? DateFormat.yMMMd().format(debt.dueDate!) : 'No Date'}\n${debt.description ?? ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currency.format(debt.amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (debt.isSettled)
            const Text('Settled', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            TextButton(
              onPressed: () {
                // Settle
                ref.read(debtProvider.notifier).settleDebt(debt.id);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 20),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Mark Paid'),
            ),
        ],
      ),
      onLongPress: () {
        // Delete
         showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Record?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  ref.read(debtProvider.notifier).deleteDebt(debt.id);
                  Navigator.pop(context);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }
}
