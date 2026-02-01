import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../scanner/data/ocr_service.dart';
import '../../../scanner/presentation/scan_receipt_screen.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../transactions_provider.dart';
import '../../../recurring/domain/recurring_transaction.dart';
import '../../../recurring/data/recurring_transaction_repository.dart';
import '../../../categories/presentation/category_provider.dart';
import '../../application/auto_categorization_service.dart';
import '../../domain/category_suggestion.dart';
import '../widgets/category_suggestion_chip.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _amount = '0';
  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  String? _accountId;
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _recurringInterval = 'Monthly';
  CategorySuggestion? _categorySuggestion;
  bool _suggestionDismissed = false;

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
    
    // Listen to note changes for auto-categorization
    _noteController.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    // Debounce and get category suggestion
    if (_noteController.text.trim().isEmpty || _suggestionDismissed) {
      setState(() {
        _categorySuggestion = null;
      });
      return;
    }

    // Get suggestion asynchronously
    _getSuggestion();
  }

  Future<void> _getSuggestion() async {
    final note = _noteController.text;
    if (note.trim().isEmpty) return;

    final service = ref.read(autoCategorizationServiceProvider);
    final categories = ref.read(categoryProvider);
    final transactions = ref.read(transactionsProvider);
    final amount = double.tryParse(_amount) ?? 0;

    final suggestion = await service.suggestCategory(
      note: note,
      amount: amount,
      availableCategories: categories.where((c) => c.type == _type.name).toList(),
      historicalTransactions: transactions,
    );

    if (suggestion != null && suggestion.isConfident && mounted) {
      setState(() {
        _categorySuggestion = suggestion;
      });
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
    final allCategories = ref.watch(categoryProvider);
    
    // Filter categories by type
    final categories = allCategories.where((c) => c.type == _type.name).toList();
    
    // Ensure _categoryId is valid for the current filtered list
    // If _categoryId is null or not in the current list, default to the first one
    if (categories.isNotEmpty) {
      final isValid = categories.any((c) => c.id == _categoryId);
      if (!isValid || _categoryId == null) {
        // We need to defer this set state or just handle it in the UI logic
        // Ideally, we select the first one.
        // NOTE: We cannot call setState here safely during build if it triggers a rebuild loop, 
        // effectively we just use the first ID for display/logic if _categoryId is invalid.
        // But for saving, we need to ensure we hold a valid ID.
        // Let's perform a post-frame callback callback ONLY if we need to sync state? 
        // Or simpler: just use a local variable for 'activeCategoryId'
        if (_categoryId == null || !isValid) {
           _categoryId = categories.first.id;
        }
      }
    }


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
                // clear category so it picks one from the new type
                _categoryId = null;
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
                     // Smart Category Suggestion
                     if (_categorySuggestion != null && !_suggestionDismissed)
                       Builder(
                         builder: (context) {
                           final allCategories = ref.watch(categoryProvider);
                           final suggestedCategory = allCategories.firstWhere(
                             (c) => c.id == _categorySuggestion!.categoryId,
                             orElse: () => allCategories.first,
                           );
                           
                           return CategorySuggestionChip(
                             suggestion: _categorySuggestion!,
                             category: suggestedCategory,
                             onAccept: () {
                               HapticFeedback.mediumImpact();
                               setState(() {
                                 _categoryId = _categorySuggestion!.categoryId;
                                 _categorySuggestion = null;
                               });
                               
                               // Learn from acceptance
                               ref.read(autoCategorizationServiceProvider).learnFromSelection(
                                 note: _noteController.text,
                                 selectedCategoryId: _categoryId!,
                                 suggestedCategoryId: _categorySuggestion?.categoryId,
                               );
                               
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text('Category applied: ${suggestedCategory.name}'),
                                   duration: const Duration(seconds: 2),
                                   behavior: SnackBarBehavior.floating,
                                 ),
                               );
                             },
                             onDismiss: () {
                               setState(() {
                                 _suggestionDismissed = true;
                                 _categorySuggestion = null;
                               });
                             },
                           );
                         },
                       ),
                     const SizedBox(height: 16),
                     // Category Selector (Simple horizontal list)
                     SizedBox(
                      height: 50,
                      child: categories.isEmpty 
                        ? Center(child: Text('No categories found', style: GoogleFonts.outfit()))
                        : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _categoryId == cat.id; 
                          return GestureDetector(
                             onTap: () {
                               HapticFeedback.lightImpact();
                               setState(() {
                                 _categoryId = cat.id;
                                 _suggestionDismissed = false; // Reset for next time
                               });
                               
                               // Learn from manual selection if we had a suggestion
                               if (_categorySuggestion != null) {
                                 ref.read(autoCategorizationServiceProvider).learnFromSelection(
                                   note: _noteController.text,
                                   selectedCategoryId: cat.id,
                                   suggestedCategoryId: _categorySuggestion?.categoryId,
                                 );
                               }
                             },
                             child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(cat.colorValue) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'), 
                                       size: 18, 
                                       color: isSelected ? Colors.white : Colors.black
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cat.name,
                                    style: GoogleFonts.outfit(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
                          onPressed: _amount == '0' || _accountId == null || _categoryId == null ? null : _saveTransaction,
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
    if (_accountId == null || _categoryId == null) return;

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
        final intermediateAccount = selectedAccount.copyWith(balance: revertedBalance);
        
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
          categoryId: _categoryId!,
          accountId: _accountId!,
          date: _selectedDate,
          note: _noteController.text,
          type: _type,
        );
        await ref.read(transactionsProvider.notifier).updateTransaction(transaction);
        
        if (mounted) context.pop();
        return; // EXIT EARLY for Same Account Edit
      }
    }

    // -- Step 2: Create/Update Transaction Record (New or Changed Account) --
    // If we are here, it's either a NEW transaction OR an edit where Account CHANGED.
    
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
      categoryId: _categoryId!,
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
        id: const Uuid().v4(),
        amount: amount,
        currencyCode: finalAccount.currencyCode,
        categoryId: _categoryId!,
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
    final result = await Navigator.push<ReceiptData>(
      context,
      MaterialPageRoute(builder: (context) => const ScanReceiptScreen()),
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          if (result.amount != null) {
            if (result.amount! % 1 == 0) {
              _amount = result.amount!.toInt().toString();
            } else {
              _amount = result.amount!.toStringAsFixed(2);
            }
          }
          if (result.date != null) {
            _selectedDate = result.date!;
          }
          if (_noteController.text.isEmpty && result.text.isNotEmpty) {
             _noteController.text = result.text; // Text from scanner is Merchant/Note
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt details applied!')));
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
