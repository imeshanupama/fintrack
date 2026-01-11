import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../domain/debt.dart';
import 'debt_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // State
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _isLent = true; // Default: I lent money (Assets)
  
  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      final newDebt = Debt(
        id: const Uuid().v4(),
        personName: _personNameController.text,
        amount: amount,
        date: _date,
        dueDate: _dueDate,
        isLent: _isLent,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );

      await ref.read(debtProvider.notifier).addDebt(newDebt);
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record added successfully')),
        );
      }
    }
  }

  Future<void> _selectDate(bool isDueDate) async {
    final initialDate = isDueDate 
        ? (_dueDate ?? DateTime.now().add(const Duration(days: 7))) 
        : _date;
        
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('I Lent'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('I Borrowed'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_isLent},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isLent = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return _isLent ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2);
                    }
                    return null;
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                     if (states.contains(MaterialState.selected)) {
                       return _isLent ? Colors.green : Colors.redAccent;
                     }
                     return null;
                  }),
                ),
              ),
              const SizedBox(height: 24),
              
              // Person Name
              TextFormField(
                controller: _personNameController,
                decoration: const InputDecoration(
                  labelText: 'Person Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat.yMMMd().format(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date (Optional)',
                          prefixIcon: Icon(Icons.event_available),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dueDate != null ? DateFormat.yMMMd().format(_dueDate!) : 'Set Date',
                          style: TextStyle(
                            color: _dueDate == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              
              // Save Button
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Record', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
