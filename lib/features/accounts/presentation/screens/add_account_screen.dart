import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/account.dart';
import '../accounts_provider.dart';
import '../../../settings/presentation/settings_provider.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  final Account? account;
  const AddAccountScreen({super.key, this.account});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  
  // Default values
  int _selectedColor = 0xFF6C63FF;
  int _selectedIcon = FontAwesomeIcons.wallet.codePoint;
  String _selectedCurrency = 'USD';

  final List<int> _colors = [
    0xFF6C63FF, // Purple
    0xFF03DAC6, // Teal
    0xFFFF5252, // Red
    0xFFFFC107, // Amber
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFF4CAF50, // Green
  ];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _selectedColor = widget.account!.colorValue;
      _selectedIcon = widget.account!.iconCode;
      _selectedCurrency = widget.account!.currencyCode;
    } else {
      // Set default currency from settings
      _selectedCurrency = ref.read(settingsProvider).currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account != null ? 'Edit Account' : 'Add Account'),
        actions: [
          if (widget.account != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAccount,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Initial Balance',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter balance' : null,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveAccount,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.account != null ? 'Update Account' : 'Create Account',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final account = Account(
        id: widget.account?.id ?? const Uuid().v4(),
        name: _nameController.text,
        balance: double.parse(_balanceController.text),
        currencyCode: _selectedCurrency,
        colorValue: _selectedColor,
        iconCode: _selectedIcon,
      );

      if (widget.account != null) {
        ref.read(accountsProvider.notifier).updateAccount(account);
      } else {
        ref.read(accountsProvider.notifier).addAccount(account);
      }
      context.pop();
    }
  }

  void _deleteAccount() {
    if (widget.account != null) {
      ref.read(accountsProvider.notifier).deleteAccount(widget.account!.id);
      context.pop();
    }
  }
}
