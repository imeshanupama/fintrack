import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../accounts/presentation/accounts_provider.dart';
import '../../transactions/presentation/transactions_provider.dart';
import 'widgets/account_card.dart';
import 'widgets/insights_widget.dart';
import 'widgets/transaction_list_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../recurring/application/recurring_transaction_service.dart';
import '../../auth/data/auth_repository.dart'; 
import '../../auth/presentation/auth_provider.dart';
import '../../savings/presentation/savings_provider.dart'; // Import SavingsProvider
import '../../currency/presentation/currency_provider.dart';
import '../../currency/domain/currency_constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check for recurring transactions on startup
    ref.read(recurringTransactionServiceProvider).checkAndGenerateTransactions();
    
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final savings = ref.watch(savingsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    
    // Currency
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final converter = ref.watch(currencyConverterProvider);
    
    // Calculate total net worth in base currency
    final totalNetWorth = converter != null
        ? converter.getTotalInCurrency(accounts, baseCurrency)
        : accounts.fold(0.0, (sum, acc) => sum + acc.balance);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {},
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome, $displayName',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${getCurrencySymbol(baseCurrency)}${totalNetWorth.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              // Currency Selector
              PopupMenuButton<String>(
                icon: Text(
                  getCurrencyFlag(baseCurrency),
                  style: const TextStyle(fontSize: 24),
                ),
                tooltip: 'Change Currency',
                onSelected: (currency) {
                  ref.read(baseCurrencyProvider.notifier).setCurrency(currency);
                },
                itemBuilder: (context) => [
                  'USD', 'EUR', 'GBP', 'JPY', 'INR', 'LKR'
                ].map((code) => PopupMenuItem(
                  value: code,
                  child: Row(
                    children: [
                      Text(getCurrencyFlag(code), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(code, style: GoogleFonts.outfit()),
                      const SizedBox(width: 8),
                      Text(getCurrencyName(code), style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )).toList(),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 18,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Accounts',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/add-account'),
                        icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220, // Increased height for better card spacing
                  child: accounts.isEmpty
                      ? Center(
                          child: InkWell(
                            onTap: () => context.push('/add-account'),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline, 
                                    size: 48, 
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No accounts yet. Tap to add!',
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            return AccountCard(account: accounts[index])
                                .animate()
                                .fadeIn(duration: 600.ms, delay: (100 * index).ms)
                                .slideX(begin: 0.2, end: 0);
                          },
                        ),
                ),
                
                // Insights Widget
                const InsightsWidget(),
                
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: GoogleFonts.outfit(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Text(
                    'No transactions yet.',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return TransactionListTile(transaction: transactions[index])
                      .animate()
                      .fadeIn(duration: 500.ms, delay: (50 * index).ms)
                      .slideY(begin: 0.1, end: 0);
                },
                childCount: transactions.length > 10 ? 10 : transactions.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (accounts.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please add an account first')),
            );
            return;
          }
           context.push('/add-transaction');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
