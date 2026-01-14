import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../debt/presentation/debt_provider.dart';
import '../../debt/domain/debt.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../accounts/presentation/accounts_provider.dart';
import '../../categories/presentation/category_provider.dart'; // Import CategoryProvider
import '../../categories/domain/category.dart';

class BillSplitScreen extends ConsumerStatefulWidget {
  const BillSplitScreen({super.key});

  @override
  ConsumerState<BillSplitScreen> createState() => _BillSplitScreenState();
}

class _BillSplitScreenState extends ConsumerState<BillSplitScreen> {
  final _amountController = TextEditingController();
  final _personController = TextEditingController();
  
  final List<String> _people = [];
  bool _includeMe = true;
  bool _addToExpenses = false;
  String? _selectedAccountId;
  String? _selectedCategoryId; // Added category selection
  
  @override
  void dispose() {
    _amountController.dispose();
    _personController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _personController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _people.add(name);
        _personController.clear();
      });
    }
  }

  void _removePerson(int index) {
    setState(() {
      _people.removeAt(index);
    });
  }

  Future<void> _saveSplits() async {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    
    if (_people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one person')));
      return;
    }

    if (_includeMe && _addToExpenses && _selectedCategoryId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category for your share')));
       return;
    }

    // Calculate Split
    final divisor = _people.length + (_includeMe ? 1 : 0);
    final amountPerPerson = totalAmount / divisor;
    
    // 1. Create Debt Records
    for (final person in _people) {
      final debt = Debt(
        id: const Uuid().v4(),
        personName: person,
        amount: double.parse(amountPerPerson.toStringAsFixed(2)),
        date: DateTime.now(),
        isLent: true, // I paid, so I lent them money
        description: 'Bill Split Share',
      );
      await ref.read(debtProvider.notifier).addDebt(debt);
    }
    
    // 2. Add to Expenses (My Share)
    if (_includeMe && _addToExpenses && _selectedAccountId != null && _selectedCategoryId != null) {
      final myShare = double.parse(amountPerPerson.toStringAsFixed(2));
      
      final accounts = ref.read(accountsProvider);
      final account = accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first);
      
      // Update Balance
      final updatedAccount = account.copyWith(balance: account.balance - myShare);
      await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
      
      // Create Transaction
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: myShare,
        currencyCode: account.currencyCode,
        categoryId: _selectedCategoryId!, // Use selected category UUID
        accountId: account.id,
        date: DateTime.now(),
        note: 'My share of bill split',
        type: TransactionType.expense,
      );
      await ref.read(transactionsProvider.notifier).addTransaction(transaction);
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Splits saved successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final allCategories = ref.watch(categoryProvider);
    // Filter only expense categories
    final expenseCategories = allCategories.where((c) => c.type == TransactionType.expense.name).toList();
    
    // Calculate preview
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    final divisor = _people.length + (_includeMe ? 1 : 0);
    final splitAmount = divisor > 0 ? totalAmount / divisor : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Split Bill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Bill Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            
            // People Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _personController,
                    decoration: const InputDecoration(
                      labelText: 'Add Person Name',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    onSubmitted: (_) => _addPerson(),
                  ),
                ),
                IconButton(
                  onPressed: _addPerson,
                  icon: const Icon(Icons.add_circle, size: 32, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // People List
            Wrap(
              spacing: 8,
              children: _people.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  onDeleted: () => _removePerson(entry.key),
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }).toList(),
            ),
            
            const Divider(height: 32),
            
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
              
            if (_includeMe && _addToExpenses && accounts.isNotEmpty)
               Column(
                 children: [
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: DropdownButtonFormField<String>(
                       value: _selectedAccountId ?? accounts.first.id,
                       decoration: const InputDecoration(labelText: 'Pay from Account'),
                       items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                       onChanged: (val) => setState(() => _selectedAccountId = val),
                     ),
                   ),
                   const SizedBox(height: 16),
                   if (expenseCategories.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       child: DropdownButtonFormField<String>(
                         value: _selectedCategoryId, // Initially null
                         hint: const Text('Select Category'),
                         decoration: const InputDecoration(
                           labelText: 'My Share Category',
                           prefixIcon: Icon(Icons.category),
                         ),
                         items: expenseCategories.map((c) => DropdownMenuItem(
                           value: c.id, 
                           child: Row(
                             children: [
                               Text(c.iconCode, style: const TextStyle(fontSize: 16)), // Simple char icon
                               const SizedBox(width: 8),
                               Text(c.name),
                             ],
                           ),
                         )).toList(),
                         onChanged: (val) => setState(() => _selectedCategoryId = val),
                       ),
                     ),
                 ],
               ),
               
            const SizedBox(height: 32),
            
            // Preview Card
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                     Text('Split Amount', style: GoogleFonts.outfit(color: Colors.grey)),
                     Text(
                       '\$${splitAmount.toStringAsFixed(2)}',
                       style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                     ),
                     const SizedBox(height: 8),
                     Text('per person (${divisor} people)', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saveSplits,
              icon: const Icon(Icons.save),
              label: const Text('Save Splits'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
