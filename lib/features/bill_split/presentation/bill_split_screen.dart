import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/bill_split.dart';
import '../domain/split_participant.dart';
import 'bill_split_provider.dart';
import 'widgets/split_method_selector.dart';
import '../../debt/presentation/debt_provider.dart';
import '../../debt/domain/debt.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../accounts/presentation/accounts_provider.dart';
import '../../categories/presentation/category_provider.dart';

class BillSplitScreen extends ConsumerStatefulWidget {
  const BillSplitScreen({super.key});

  @override
  ConsumerState<BillSplitScreen> createState() => _BillSplitScreenState();
}

class _BillSplitScreenState extends ConsumerState<BillSplitScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _personController = TextEditingController();
  final _customAmountController = TextEditingController();

  SplitMethod _splitMethod = SplitMethod.equal;
  final List<Map<String, dynamic>> _participants = [];
  bool _includeMe = true;
  bool _addToExpenses = false;
  bool _createDebtRecords = true;
  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _personController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final name = _personController.text.trim();
    if (name.isEmpty) return;

    final amount = _splitMethod == SplitMethod.custom
        ? double.tryParse(_customAmountController.text) ?? 0.0
        : 0.0;

    setState(() {
      _participants.add({'name': name, 'amount': amount});
      _personController.clear();
      _customAmountController.clear();
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  Map<String, double> _calculateSplits() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    final splits = <String, double>{};

    if (_splitMethod == SplitMethod.equal) {
      final divisor = _participants.length + (_includeMe ? 1 : 0);
      if (divisor > 0) {
        final amountPerPerson = totalAmount / divisor;
        for (var p in _participants) {
          splits[p['name']] = amountPerPerson;
        }
        if (_includeMe) {
          splits['Me'] = amountPerPerson;
        }
      }
    } else if (_splitMethod == SplitMethod.custom) {
      for (var p in _participants) {
        splits[p['name']] = p['amount'] ?? 0.0;
      }
      if (_includeMe) {
        final othersTotal = splits.values.fold(0.0, (sum, amount) => sum + amount);
        splits['Me'] = totalAmount - othersTotal;
      }
    }

    return splits;
  }

  Future<void> _saveSplit() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one participant')),
      );
      return;
    }

    if (_includeMe && _addToExpenses && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category for your share')),
      );
      return;
    }

    final splits = _calculateSplits();
    final accounts = ref.read(accountsProvider);
    final account = accounts.isNotEmpty
        ? accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first)
        : null;

    String? transactionId;
    double? myShare;

    // Create transaction for my share if needed
    if (_includeMe && _addToExpenses && account != null && _selectedCategoryId != null) {
      myShare = splits['Me'];
      if (myShare != null && myShare > 0) {
        // Update account balance
        final updatedAccount = account.copyWith(balance: account.balance - myShare);
        await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);

        // Create transaction
        transactionId = const Uuid().v4();
        final transaction = Transaction(
          id: transactionId,
          amount: myShare,
          currencyCode: account.currencyCode,
          categoryId: _selectedCategoryId!,
          accountId: account.id,
          date: DateTime.now(),
          note: 'My share: ${_titleController.text}',
          type: TransactionType.expense,
        );
        await ref.read(transactionsProvider.notifier).addTransaction(transaction);
      }
    }

    // Create BillSplit record
    final participants = _participants.map((p) {
      return SplitParticipant(
        name: p['name'],
        amount: splits[p['name']] ?? 0.0,
      );
    }).toList();

    final billSplit = BillSplit(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      totalAmount: totalAmount,
      currencyCode: account?.currencyCode ?? 'USD',
      date: DateTime.now(),
      participants: participants,
      myShare: myShare,
      transactionId: transactionId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(billSplitNotifierProvider).addBillSplit(billSplit);

    // Optionally create debt records
    if (_createDebtRecords) {
      for (var p in participants) {
        final debt = Debt(
          id: const Uuid().v4(),
          personName: p.name,
          amount: p.amount,
          date: DateTime.now(),
          isLent: true,
          description: 'Bill Split: ${_titleController.text}',
        );
        await ref.read(debtProvider.notifier).addDebt(debt);
      }
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill split created successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final allCategories = ref.watch(categoryProvider);
    final expenseCategories = allCategories.where((c) => c.type == TransactionType.expense.name).toList();
    final splits = _calculateSplits();

    return Scaffold(
      appBar: AppBar(title: const Text('Split Bill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Bill Title',
                hintText: 'e.g., Dinner at Restaurant',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Note Input
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Split Method Selector
            Text('Split Method', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SplitMethodSelector(
              selectedMethod: _splitMethod,
              onMethodChanged: (method) => setState(() => _splitMethod = method),
            ),
            const SizedBox(height: 24),

            // Participants Input
            Text('Participants', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _personController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_add),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _splitMethod == SplitMethod.custom ? null : _addParticipant(),
                  ),
                ),
                if (_splitMethod == SplitMethod.custom) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addParticipant(),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addParticipant,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Participants List
            if (_participants.isNotEmpty) ...[
              ...List.generate(_participants.length, (index) {
                final participant = _participants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(participant['name'][0].toUpperCase())),
                    title: Text(participant['name'], style: GoogleFonts.outfit()),
                    subtitle: splits.containsKey(participant['name'])
                        ? Text('\$${splits[participant['name']]!.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(color: Colors.grey))
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removeParticipant(index),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 16),

            // Options
            SwitchListTile(
              title: const Text('Include Me'),
              subtitle: const Text('I am part of the split'),
              value: _includeMe,
              onChanged: (val) => setState(() => _includeMe = val),
            ),

            if (_includeMe)
              SwitchListTile(
                title: const Text('Add My Share to Expenses'),
                value: _addToExpenses,
                onChanged: (val) => setState(() => _addToExpenses = val),
              ),

            SwitchListTile(
              title: const Text('Create Debt Records'),
              subtitle: const Text('Track as debts owed to you'),
              value: _createDebtRecords,
              onChanged: (val) => setState(() => _createDebtRecords = val),
            ),

            if (_includeMe && _addToExpenses && accounts.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAccountId ?? accounts.first.id,
                decoration: const InputDecoration(
                  labelText: 'Pay from Account',
                  border: OutlineInputBorder(),
                ),
                items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
              const SizedBox(height: 16),
              if (expenseCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  hint: const Text('Select Category'),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: expenseCategories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(c.icon, size: 20),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
            ],

            const SizedBox(height: 24),

            // Preview Card
            if (splits.isNotEmpty)
              Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Split Preview', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      ...splits.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key, style: GoogleFonts.outfit()),
                              Text('\$${entry.value.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveSplit,
              icon: const Icon(Icons.save),
              label: const Text('Create Split'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
