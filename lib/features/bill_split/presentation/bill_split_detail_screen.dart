import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../domain/bill_split.dart';
import 'bill_split_provider.dart';

class BillSplitDetailScreen extends ConsumerWidget {
  final BillSplit billSplit;

  const BillSplitDetailScreen({super.key, required this.billSplit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final notifier = ref.read(billSplitNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context, ref, notifier);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            billSplit.title,
                            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(
                          billSplit.isFullySettled ? Icons.check_circle : Icons.pending,
                          color: billSplit.isFullySettled ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${billSplit.currencyCode} ${billSplit.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(billSplit.date),
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                    if (billSplit.note != null && billSplit.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        billSplit.note!,
                        style: GoogleFonts.outfit(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Card
            if (!billSplit.isFullySettled)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pending Amount', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            Text(
                              '${billSplit.currencyCode} ${billSplit.pendingAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Participants Section
            Text('Participants', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...billSplit.participants.map((participant) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: participant.isPaid ? Colors.green : Colors.grey,
                    child: Text(
                      participant.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(participant.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: participant.isPaid && participant.paidDate != null
                      ? Text('Paid on ${dateFormat.format(participant.paidDate!)}',
                          style: GoogleFonts.outfit(color: Colors.green, fontSize: 12))
                      : Text('Not paid', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${billSplit.currencyCode} ${participant.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (!participant.isPaid)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          onPressed: () {
                            _markAsPaid(context, ref, notifier, participant.name);
                          },
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            // My Share Section
            if (billSplit.myShare != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Share', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            Text(
                              '${billSplit.currencyCode} ${billSplit.myShare!.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (billSplit.transactionId != null)
                              Text('Added to expenses', style: GoogleFonts.outfit(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 24),
            if (!billSplit.isFullySettled)
              FilledButton.icon(
                onPressed: () {
                  _markAllAsPaid(context, ref, notifier);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark All as Paid'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _markAsPaid(BuildContext context, WidgetRef ref, BillSplitNotifier notifier, String participantName) async {
    await notifier.markParticipantAsPaid(billSplit.id, participantName);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$participantName marked as paid')),
      );
    }
  }

  void _markAllAsPaid(BuildContext context, WidgetRef ref, BillSplitNotifier notifier) async {
    await notifier.markAllParticipantsAsPaid(billSplit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All participants marked as paid')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, BillSplitNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Split?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await notifier.deleteBillSplit(billSplit.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                context.pop(); // Go back to list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Split deleted')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
