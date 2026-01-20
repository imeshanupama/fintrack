import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/currency_constants.dart';
import 'currency_provider.dart';

class CurrencySettingsScreen extends ConsumerWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final updateState = ref.watch(currencyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        actions: [
          IconButton(
            icon: updateState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: updateState.isLoading
                ? null
                : () {
                    ref.read(currencyNotifierProvider.notifier).updateRates();
                  },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Base Currency Selection
          Text(
            'Preferred Currency',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Text(
                getCurrencyFlag(baseCurrency),
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                getCurrencyName(baseCurrency),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                baseCurrency,
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCurrencyPicker(context, ref),
            ),
          ),
          const SizedBox(height: 32),

          // Exchange Rates
          Text(
            'Exchange Rates',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ratesAsync.when(
            data: (rates) {
              if (rates.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.currency_exchange, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No exchange rates yet',
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(currencyNotifierProvider.notifier).updateRates();
                          },
                          child: const Text('Fetch Rates'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Get popular currencies only
              final popularRates = rates.values
                  .where((rate) => popularCurrencies.contains(rate.targetCurrency))
                  .toList()
                ..sort((a, b) => a.targetCurrency.compareTo(b.targetCurrency));

              final lastUpdated = popularRates.isNotEmpty
                  ? popularRates.first.lastUpdated
                  : DateTime.now();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Updated ${_formatTimestamp(lastUpdated)}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  ...popularRates.map((rate) => Card(
                        child: ListTile(
                          leading: Text(
                            getCurrencyFlag(rate.targetCurrency),
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            rate.targetCurrency,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            rate.rate.toStringAsFixed(4),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load rates',
                      style: GoogleFonts.outfit(color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: currencies.keys.map((code) {
          final info = currencies[code]!;
          return ListTile(
            leading: Text(info.flag, style: const TextStyle(fontSize: 24)),
            title: Text(info.name, style: GoogleFonts.outfit()),
            subtitle: Text(code, style: GoogleFonts.outfit(color: Colors.grey)),
            onTap: () {
              ref.read(currencyNotifierProvider.notifier).setBaseCurrency(code);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
