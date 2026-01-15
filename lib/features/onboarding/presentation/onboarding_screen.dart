import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../settings/data/settings_repository.dart'; // Correct import
import '../../accounts/presentation/accounts_provider.dart';
import '../../accounts/domain/account.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  
  // State for Currency Page
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'INR', 'LKR'];

  // State for Account Page
  final _accountNameController = TextEditingController();
  final _balanceController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
  }

  Future<void> _finishOnboarding() async {
    // 1. Save Currency
    await ref.read(settingsRepositoryProvider).setCurrency(_selectedCurrency);

    // 2. Create First Account (if provided)
    if (_accountNameController.text.isNotEmpty) {
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      final account = Account(
        id: const Uuid().v4(),
        name: _accountNameController.text,
        balance: balance,
        currencyCode: _selectedCurrency,
        colorValue: Colors.blue.value,
        iconCode: Icons.account_balance_wallet.codePoint, // Default icon
      );
      await ref.read(accountsProvider.notifier).addAccount(account);
    }

    // 3. Mark Onboarding as Complete
    await ref.read(settingsRepositoryProvider).setHasCompletedOnboarding(true);

    // 4. Navigate to Home
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce flow
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(),
                  _buildCurrencyPage(),
                  _buildAccountPage(),
                ],
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(3, (index) => 
                      AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next/Finish Button
                  FilledButton(
                    onPressed: _currentPage == 2 ? _finishOnboarding : _nextPage,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes, size: 100, color: Theme.of(context).primaryColor)
              .animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            'Welcome to FinTrack',
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            'Take control of your finances. Track expenses, manage budgets, and achieve your saving goals.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildCurrencyPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Select Currency',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the default currency for your transactions.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                final currency = _currencies[index];
                final isSelected = _selectedCurrency == currency;
                return Card(
                  elevation: isSelected ? 4 : 0,
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(currency, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).primaryColor : null)),
                    trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                    onTap: () => setState(() => _selectedCurrency = currency),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPage() {
    return SingleChildScrollView( // Handling keyboard
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Create First Account',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an account to start tracking immediately. You can skip this and add one later.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _accountNameController,
            decoration: const InputDecoration(
              labelText: 'Account Name (e.g., Wallet, Bank)',
              prefixIcon: Icon(Icons.account_balance_wallet),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current Balance',
              prefixText: '$_selectedCurrency ',
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
