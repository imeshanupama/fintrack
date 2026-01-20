import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Transaction> _getEventsForDay(DateTime day, List<Transaction> allTransactions) {
    return allTransactions.where((t) {
      return isSameDay(t.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final selectedTransactions = _getEventsForDay(_selectedDay!, transactions);

    // Calculate daily total
    double income = 0;
    double expense = 0;
    for (var t in selectedTransactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<Transaction>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) => _getEventsForDay(day, transactions),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8),
          
          // Daily Summary
          if (selectedTransactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryChip('Income', income, Colors.green),
                _buildSummaryChip('Expense', expense, Colors.red),
              ],
            ),
          ),
          
          const Divider(),
          
          // Transaction List
          Expanded(
            child: selectedTransactions.isEmpty
                ? Center(child: Text("No transactions", style: GoogleFonts.outfit(color: Colors.grey)))
                : ListView.builder(
                    itemCount: selectedTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = selectedTransactions[index];
                      final isExpense = tx.type == TransactionType.expense;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExpense ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          child: Icon(
                             // Use a default icon since we don't have easy category lookup here unless we fetch categories
                             // Assuming categoryId is readable or we just show generic
                             isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                             color: isExpense ? Colors.red : Colors.green,
                             size: 16,
                          ),
                        ),
                        title: Text(tx.note.isEmpty ? 'Transaction' : tx.note, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                        subtitle: Text(DateFormat('hh:mm a').format(tx.date)),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            color: isExpense ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            '$label: \$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
