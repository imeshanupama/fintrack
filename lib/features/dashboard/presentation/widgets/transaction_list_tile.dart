import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_type.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/settings_provider.dart';

class TransactionListTile extends ConsumerWidget {
  final Transaction transaction;

  const TransactionListTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).currency;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final prefix = isIncome ? '+' : '-';
    final amountFormatted = _formatCurrency(transaction.amount, currency);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(
        transaction.categoryId, // TODO: Replace with Category Name lookup
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        DateFormat('MMM d, y h:mm a').format(transaction.date),
        style: GoogleFonts.outfit(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        '$prefix$amountFormatted',
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () => context.push('/add-transaction', extra: transaction),
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    String symbol = '\$';
    if (currencyCode == 'EUR') symbol = '€';
    if (currencyCode == 'GBP') symbol = '£';
    if (currencyCode == 'JPY') symbol = '¥';
    if (currencyCode == 'INR') symbol = '₹';
    if (currencyCode == 'LKR') symbol = 'Rs ';
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
