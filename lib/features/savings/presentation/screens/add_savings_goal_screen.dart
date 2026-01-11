import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/savings_goal.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../savings_provider.dart';

class AddSavingsGoalScreen extends ConsumerStatefulWidget {
  final SavingsGoal? goal;
  const AddSavingsGoalScreen({super.key, this.goal});

  @override
  ConsumerState<AddSavingsGoalScreen> createState() => _AddSavingsGoalScreenState();
}

class _AddSavingsGoalScreenState extends ConsumerState<AddSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currrentAmountController = TextEditingController(text: '0');

  int _selectedColor = 0xFF6C63FF;
  int _selectedIcon = FontAwesomeIcons.piggyBank.codePoint;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetController.text = widget.goal!.targetAmount.toStringAsFixed(0);
      _currrentAmountController.text = widget.goal!.savedAmount.toStringAsFixed(0);
      _selectedColor = widget.goal!.colorValue;
      _selectedIcon = widget.goal!.iconCode;
    }
  }

  final List<int> _colors = [
    0xFF6C63FF, 0xFF03DAC6, 0xFFFF5252, 0xFFFFC107, 0xFF2196F3, 0xFF4CAF50
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
      appBar: AppBar(title: Text(widget.goal != null ? 'Edit Savings Goal' : 'New Savings Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Goal Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(labelText: 'Target Amount', prefixText: symbol),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currrentAmountController,
                decoration: InputDecoration(labelText: 'Current Saved', prefixText: symbol),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _colors.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      backgroundColor: Color(color),
                      radius: 16,
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saveGoal,
                child: SizedBox(
                   width: double.infinity,
                   child: Center(
                     child: Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Text(widget.goal != null ? 'Update Goal' : 'Create Goal', style: GoogleFonts.outfit(fontSize: 16)),
                     ),
                   ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final id = widget.goal?.id ?? const Uuid().v4();
      final goal = SavingsGoal(
        id: id,
        name: _nameController.text,
        targetAmount: double.parse(_targetController.text),
        savedAmount: double.tryParse(_currrentAmountController.text) ?? 0,
        currencyCode: ref.read(settingsProvider).currency,
        colorValue: _selectedColor,
        iconCode: _selectedIcon,
      );
      
      if (widget.goal != null) {
        ref.read(savingsProvider.notifier).updateGoal(goal);
      } else {
        ref.read(savingsProvider.notifier).addGoal(goal);
      }
      context.pop();
    }
  }
}
