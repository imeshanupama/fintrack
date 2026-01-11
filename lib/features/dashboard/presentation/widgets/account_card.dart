import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import 'package:intl/intl.dart';

class AccountCard extends ConsumerWidget {
  final Account account;

  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).currency;
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(account.colorValue).withOpacity(0.8),
            Color(account.colorValue),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(account.colorValue).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glassmorphism effect overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconData(account.iconCode, fontFamily: 'MaterialIcons'),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.7)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.push('/add-account', extra: account);
                        } else if (value == 'delete') {
                           showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Account?'),
                              content: Text('Are you sure you want to delete "${account.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                FilledButton(
                                  onPressed: () {
                                    ref.read(accountsProvider.notifier).deleteAccount(account.id);
                                    Navigator.pop(context);
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit Account'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Account', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(account.balance, currency),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    // Simple formatter, can be improved with intl
    String symbol = '\$';
    if (currencyCode == 'EUR') symbol = '€';
    if (currencyCode == 'GBP') symbol = '£';
    if (currencyCode == 'JPY') symbol = '¥';
    if (currencyCode == 'INR') symbol = '₹';
    if (currencyCode == 'LKR') symbol = 'Rs ';
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
