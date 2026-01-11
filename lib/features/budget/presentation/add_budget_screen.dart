import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../budget/domain/budget.dart';
import '../../budget/presentation/budget_provider.dart';
import '../../settings/presentation/settings_provider.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final Budget? budget;
  const AddBudgetScreen({super.key, this.budget});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _category = 'Food';
  final _period = 'Monthly'; // Hardcoded for MVP

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toStringAsFixed(0);
      _category = widget.budget!.categoryId;
      // _period = widget.budget!.period; // if period becomes dynamic
    }
  }

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).currency;
    String symbol = '\$';
    if (currency == 'EUR') symbol = '€';
    if (currency == 'GBP') symbol = '£';
    if (currency == 'JPY') symbol = '¥';
    if (currency == 'INR') symbol = '₹';
    if (currency == 'LKR') symbol = 'Rs ';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget != null ? 'Edit Budget' : 'New Budget'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Set a spending limit for a category',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Limit Amount',
                prefixText: '$symbol ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter amount';
                if (double.tryParse(value) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Period selector could go here
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _saveBudget,
                child: Text(widget.budget != null ? 'Update Budget' : 'Save Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final id = widget.budget?.id ?? const Uuid().v4();
      final budget = Budget(
        id: id,
        categoryId: _category,
        amount: double.parse(_amountController.text),
        period: _period,
      );

      if (widget.budget != null) {
        ref.read(budgetProvider.notifier).updateBudget(budget);
      } else {
        ref.read(budgetProvider.notifier).addBudget(budget);
      }
      context.pop();
    }
  }
}
