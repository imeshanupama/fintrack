import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../scanner/data/ocr_service.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../../accounts/domain/account.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../transactions_provider.dart';
import '../../../recurring/domain/recurring_transaction.dart';
import '../../../recurring/data/recurring_transaction_repository.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _amount = '0';
  TransactionType _type = TransactionType.expense;
  String _categoryId = 'Food';
  String? _accountId;
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _recurringInterval = 'Monthly';

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Salary',
    'Health',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    // Default to first account if available
    final accounts = ref.read(accountsProvider);
    if (widget.transaction != null) {
      _amount = widget.transaction!.amount.toStringAsFixed(0); // Converting to string logic
      if (widget.transaction!.amount % 1 != 0) {
        _amount = widget.transaction!.amount.toString();
      }
      _type = widget.transaction!.type;
      _categoryId = widget.transaction!.categoryId;
      _accountId = widget.transaction!.accountId;
      _noteController.text = widget.transaction!.note;
      _selectedDate = widget.transaction!.date;
    } else if (accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }
  }

  void _onKeyTap(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amount == '0') {
        _amount = value;
      } else {
        _amount += value;
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : (_type == TransactionType.income ? 'Income' : 'Expense')),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteTransaction,
            ),
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: _scanReceipt,
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _type = _type == TransactionType.expense
                    ? TransactionType.income
                    : TransactionType.expense;
              });
            },
            child: Text(
              _type == TransactionType.expense ? 'Switch to Income' : 'Switch to Expense',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    Text(
                      _amount,
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _type == TransactionType.income ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Date Selector
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat.yMMMd().format(_selectedDate),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Account Selector
                    if (accounts.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24.0),
                         child: DropdownButtonFormField<String>(
                           value: _accountId,
                           decoration: InputDecoration(
                             labelText: 'Account',
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                           items: accounts.map((a) {
                             return DropdownMenuItem(
                               value: a.id,
                               child: Text(a.name),
                             );
                           }).toList(),
                           onChanged: (val) => setState(() => _accountId = val),
                           validator: (val) => val == null ? 'Select Account' : null,
                         ),
                       ),
                    const SizedBox(height: 16),
                    // Category Selector (Simple horizontal list)
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _categoryId == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _categoryId = cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                     const SizedBox(height: 16),
                    // Note Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Add a note...',
                          border: InputBorder.none,
                          icon: const Icon(Icons.edit_note),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Recurring Toggle
                    SwitchListTile(
                      title: Text('Recurring Transaction', style: GoogleFonts.outfit()),
                      value: _isRecurring,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _isRecurring = val);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    if (_isRecurring)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: DropdownButtonFormField<String>(
                          value: _recurringInterval,
                          decoration: InputDecoration(
                            labelText: 'Repeat Interval',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                              .toList(),
                          onChanged: (val) => setState(() => _recurringInterval = val!),
                        ),
                      ),
                    const Spacer(),
                    // Custom Keypad
                    _buildKeypad(),
                    const SizedBox(height: 24),
                    // Save Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _amount == '0' || _accountId == null ? null : _saveTransaction,
                          child: Text('Save', style: GoogleFonts.outfit(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _keypadButton('1'),
            _keypadButton('2'),
            _keypadButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _keypadButton('4'),
            _keypadButton('5'),
            _keypadButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _keypadButton('7'),
            _keypadButton('8'),
            _keypadButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _keypadButton('.'),
            _keypadButton('0'),
            IconButton(
              onPressed: _onBackspace,
              icon: const Icon(Icons.backspace_outlined),
              iconSize: 28,
            ),
          ],
        ),
      ],
    );
  }

  Widget _keypadButton(String label) {
    return InkWell(
      onTap: () => _onKeyTap(label),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 80,
        height: 60,
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction() async {
    final oldTx = widget.transaction!;
    final accounts = ref.read(accountsProvider);
    final account = accounts.firstWhere((a) => a.id == oldTx.accountId, orElse: () => accounts.first);
    
    // Revert balance
    double balance = account.balance;
    if (oldTx.type == TransactionType.income) {
      balance -= oldTx.amount;
    } else {
      balance += oldTx.amount;
    }
    
    final updatedAccount = account.copyWith(balance: balance);
    await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
    await ref.read(transactionsProvider.notifier).deleteTransaction(oldTx.id);
    
    if (mounted) context.pop();
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amount);
    if (amount == null || amount == 0) return;
    if (_accountId == null) return;

    final accounts = ref.read(accountsProvider); // Current state
    final selectedAccount = accounts.firstWhere((a) => a.id == _accountId);

    // If Editing
    if (widget.transaction != null) {
      final oldTx = widget.transaction!;
      final oldAccountId = oldTx.accountId;
      
      // -- Step 1: Handle Old Account / Revert Old Transaction --
      if (oldAccountId != _accountId) {
        // CASE A: Account Changed
        // 1. Revert from Old Account
        final oldAccount = accounts.firstWhere((a) => a.id == oldAccountId, orElse: () => selectedAccount);
        // Only proceed if we actually found the distinct old account (or safe fallback)
        if (oldAccount.id == oldAccountId) {
            double oldAccBalance = oldAccount.balance;
            if (oldTx.type == TransactionType.income) {
               oldAccBalance -= oldTx.amount;
            } else {
               oldAccBalance += oldTx.amount;
            }
            // Save Old Account immediately
            await ref.read(accountsProvider.notifier).updateAccount(oldAccount.copyWith(balance: oldAccBalance));
        }

        // 2. Prepare New Account (selectedAccount)
        // We will apply the new transaction to 'selectedAccount' below.
        // But first, we need to ensure we have the LATEST version of selectedAccount 
        // in case the update above somehow affected it (unlikely but safe).
        // Since we are about to modify 'selectedAccount', let's use the one we have, 
        // as we haven't touched it yet in this branch.

      } else {
        // CASE B: Same Account
        // We need to revert the old transaction's effect on 'selectedAccount' first.
        double revertedBalance = selectedAccount.balance;
        if (oldTx.type == TransactionType.income) {
          revertedBalance -= oldTx.amount;
        } else {
          revertedBalance += oldTx.amount;
        }
        // We DO NOT save yet. We will apply the new transaction to this 'revertedBalance'.
        // Update our local 'selectedAccount' variable to reflect this intermediate state.
        // specific: force update the variable so the next block uses the reverted balance.
        // We use a temp variable for the logic below.
        final intermediateAccount = selectedAccount.copyWith(balance: revertedBalance);
        
        // This is the tricky part: we want to apply the NEW transaction to this intermediate account.
        // We can just proceed to the "Apply New Transaction" block, but we must ensure
        // it uses 'intermediateAccount' as the base.
        
        // Let's refactor:
        // We will calculate 'finalBalance' here and save ONCE.
        
        double finalBalance = revertedBalance;
        if (_type == TransactionType.income) {
           finalBalance += amount;
        } else {
           finalBalance -= amount;
        }
        
        final finalAccount = intermediateAccount.copyWith(balance: finalBalance);
        await ref.read(accountsProvider.notifier).updateAccount(finalAccount);
        
        // Update Transaction Record
        final transaction = Transaction(
          id: widget.transaction!.id,
          amount: amount,
          currencyCode: finalAccount.currencyCode,
          categoryId: _categoryId,
          accountId: _accountId!,
          date: _selectedDate,
          note: _noteController.text,
          type: _type,
        );
        await ref.read(transactionsProvider.notifier).updateTransaction(transaction);
        
        // Handle Recurring Update? (Optional complexity, skipping for now as per original)
        if (mounted) context.pop();
        return; // EXIT EARLY for Same Account Edit
      }
    }

    // -- Step 2: Create/Update Transaction Record (New or Changed Account) --
    // If we are here, it's either a NEW transaction OR an edit where Account CHANGED.
    // In both cases, 'selectedAccount' (as fetched initially) is the target for the NEW amount.
    // (If account changed, we already reverted old account above).

    // Refetch account to be absolutely safe?
    // Not strictly necessary if we are confident, but let's just use the clean 'selectedAccount'
    // since we haven't modified it yet in this flow (only oldAccount was modified).
    
    double newBalance = selectedAccount.balance;
    if (_type == TransactionType.income) {
      newBalance += amount;
    } else {
      newBalance -= amount;
    }
    
    final finalAccount = selectedAccount.copyWith(balance: newBalance);
    await ref.read(accountsProvider.notifier).updateAccount(finalAccount);

    final transaction = Transaction(
      id: widget.transaction?.id ?? const Uuid().v4(),
      amount: amount,
      currencyCode: finalAccount.currencyCode,
      categoryId: _categoryId,
      accountId: _accountId!, // The NEW account ID
      date: _selectedDate,
      note: _noteController.text,
      type: _type,
    );

    if (widget.transaction != null) {
      await ref.read(transactionsProvider.notifier).updateTransaction(transaction);
    } else {
      await ref.read(transactionsProvider.notifier).addTransaction(transaction);
    }
    
    // -- Step 3: Handle Recurring --
    if (_isRecurring) {
      final repository = ref.read(recurringTransactionRepositoryProvider);
      
      // Calculate next due date
      DateTime nextDate = _selectedDate;
      switch (_recurringInterval) {
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

      final recurring = RecurringTransaction(
        id: const Uuid().v4(), // Always new ID for recurring rule? Or link it? keeping simple
        amount: amount,
        currencyCode: finalAccount.currencyCode,
        categoryId: _categoryId,
        accountId: _accountId!,
        note: _noteController.text,
        type: _type,
        interval: _recurringInterval,
        nextDueDate: nextDate,
      );
      
      await repository.add(recurring.id, recurring);
    }

    if (mounted) context.pop();
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context, 
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.image), title: const Text('Gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ],
      )
    );
    if (source == null) return;

    final ocr = ref.read(ocrServiceProvider);
    final path = await ocr.pickImage(source);
    if (path == null) return;

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning receipt...')));
    }

    try {
      final data = await ocr.scanReceipt(path);
      setState(() {
         if (data.amount != null) {
            // Check if int or decimal
            if (data.amount! % 1 == 0) {
               _amount = data.amount!.toInt().toString(); 
            } else {
               _amount = data.amount!.toStringAsFixed(2);
            }
         }
         if (data.date != null) _selectedDate = data.date!;
         if (_noteController.text.isEmpty) _noteController.text = "Scanned Receipt";
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt scanned!')));
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
       }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
