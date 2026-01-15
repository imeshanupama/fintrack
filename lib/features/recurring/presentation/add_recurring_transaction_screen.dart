import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../transactions/domain/transaction_type.dart';
import '../../categories/presentation/category_provider.dart';
import '../../accounts/presentation/accounts_provider.dart';
import '../../recurring/domain/recurring_transaction.dart';
import 'recurring_provider.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? recurringTransaction;

  const AddRecurringTransactionScreen({super.key, this.recurringTransaction});

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() => _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState extends ConsumerState<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String _interval = 'Monthly'; // Daily, Weekly, Monthly, Yearly
  DateTime _nextDueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.recurringTransaction != null) {
      final rt = widget.recurringTransaction!;
      _amountController.text = rt.amount.toString();
      _noteController.text = rt.note;
      _selectedType = rt.type;
      _selectedCategoryId = rt.categoryId;
      _selectedAccountId = rt.accountId;
      _interval = rt.interval;
      _nextDueDate = rt.nextDueDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null || _selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select category and account')),
        );
        return;
      }

      final accounts = ref.read(accountsProvider);
      final account = accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first);

      final newRecurring = RecurringTransaction(
        id: widget.recurringTransaction?.id ?? const Uuid().v4(),
        amount: double.parse(_amountController.text),
        currencyCode: account.currencyCode,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        note: _noteController.text,
        type: _selectedType,
        interval: _interval,
        nextDueDate: _nextDueDate,
      );

      if (widget.recurringTransaction == null) {
        await ref.read(recurringTransactionsProvider.notifier).addRecurringTransaction(newRecurring);
      } else {
        await ref.read(recurringTransactionsProvider.notifier).updateRecurringTransaction(newRecurring);
      }

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider)
        .where((c) => c.type == _selectedType.name)
        .toList();
    final accounts = ref.watch(accountsProvider);

    // Ensure selected category/account is valid for the current list (reset if needed)
    if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
       _selectedCategoryId = null;
    }
    if (_selectedAccountId != null && !accounts.any((a) => a.id == _selectedAccountId)) {
       _selectedAccountId = null;
    }
    // Set defaults if null and lists available
    if (_selectedCategoryId == null && categories.isNotEmpty) {
       _selectedCategoryId = categories.first.id;
    }
    if (_selectedAccountId == null && accounts.isNotEmpty) {
       _selectedAccountId = accounts.first.id;
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recurringTransaction == null ? 'Add Recurring' : 'Edit Recurring'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type Toggle
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                  _selectedCategoryId = null; // Reset category on type change
                });
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter amount';
                if (double.tryParse(value) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

             // Note
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (e.g. Netflix)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Please enter a note' : null,
            ),
             const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: categories.map((c) => DropdownMenuItem(
                value: c.id,
                child: Row(children: [
                   Icon(c.icon, size: 18, color: c.color), 
                   const SizedBox(width: 8), 
                   Text(c.name)
                ]),
              )).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Account Dropdown
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Account',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              items: accounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text(a.name),
              )).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
               validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Interval
             DropdownButtonFormField<String>(
              value: _interval,
              decoration: const InputDecoration(
                labelText: 'Repeat Interval',
                prefixIcon: Icon(Icons.repeat),
                border: OutlineInputBorder(),
              ),
              items: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((i) => DropdownMenuItem(
                value: i,
                child: Text(i),
              )).toList(),
              onChanged: (val) => setState(() => _interval = val!),
            ),
            const SizedBox(height: 16),

            // Next Due Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('First/Next Due Date'),
              subtitle: Text(DateFormat('MMM d, y').format(_nextDueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Recurring Transaction'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
