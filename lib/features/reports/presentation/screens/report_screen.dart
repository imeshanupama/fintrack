import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/report_provider.dart';
import '../../../settings/application/data_export_service.dart';
import '../../../transactions/presentation/transactions_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_type.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String _selectedPeriod = 'This Month';
  DateTimeRange? _customRange;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports', style: GoogleFonts.outfit()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Period',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['This Month', 'Last Month', 'This Year', 'Custom'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPeriod = val!;
                  if (val == 'Custom') {
                    _pickCustomRange();
                  } else {
                    _customRange = null;
                  }
                });
              },
            ),
            if (_selectedPeriod == 'Custom' && _customRange != null) ...[
              const SizedBox(height: 10),
              Text(
                '${DateFormat('MMM d, y').format(_customRange!.start)} - ${DateFormat('MMM d, y').format(_customRange!.end)}',
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ],

            
            const SizedBox(height: 20),
            
            // Pie Chart Section
            Expanded(
              child: _buildCategoryPieChart(ref, settings.currency),
            ),
            
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isGenerating ? null : () => _generateReport(settings.currency),
              icon: _isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGenerating ? 'Generating...' : 'Generate PDF Report'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                 try {
                  await ref.read(dataExportServiceProvider).exportTransactionsToCsv();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.table_chart),
              label: const Text('Export All to CSV'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
      });
    } else {
       // Revert if cancelled
       if (_customRange == null) {
         setState(() {
           _selectedPeriod = 'This Month';
         });
       }
    }
  }

  Future<void> _generateReport(String currency) async {
    setState(() => _isGenerating = true);
    try {
      final now = DateTime.now();
      DateTime start;
      DateTime end = now;

      switch (_selectedPeriod) {
        case 'This Month':
          start = DateTime(now.year, now.month, 1);
          break;
        case 'Last Month':
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0); // Last day of prev month
          break;
        case 'This Year':
          start = DateTime(now.year, 1, 1);
          break;
        case 'Custom':
          if (_customRange == null) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date range')));
             setState(() => _isGenerating = false);
             return;
          }
          start = _customRange!.start;
          end = _customRange!.end;
          break;
        default:
          start = DateTime(now.year, now.month, 1);
      }

      // Ensure end date includes the full day
      end = DateTime(end.year, end.month, end.day, 23, 59, 59);

      // Fetch transactions
      // Get all transactions from provider (assuming it's loaded)
      final transactions = ref.read(transactionsProvider);
      
      final filtered = transactions.where((t) {
        return t.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
               t.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions found for this period')));
        }
        return;
      }

      await ref.read(reportServiceProvider).generateAndPrintPdf(
        transactions: filtered,
        startDate: start,
        endDate: end,
        currencySymbol: currency, // Get from settings
      );

    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }


  Widget _buildCategoryPieChart(WidgetRef ref, String currency) {
    // 1. Filter Transactions for current range
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_selectedPeriod) {
        case 'This Month':
          start = DateTime(now.year, now.month, 1);
          break;
        case 'Last Month':
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case 'This Year':
          start = DateTime(now.year, 1, 1);
          break;
        case 'Custom':
          if (_customRange == null) return const SizedBox.shrink();
          start = _customRange!.start;
          end = _customRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
          break;
        default:
          start = DateTime(now.year, now.month, 1);
    }
    
    final transactions = ref.watch(transactionsProvider);
    final filtered = transactions.where((t) {
       return t.type == TransactionType.expense &&
              t.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
              t.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
    
    if (filtered.isEmpty) {
      return Center(child: Text('No expenses for this period', style: GoogleFonts.outfit(color: Colors.grey)));
    }
    
    // 2. Aggregate by Category
    final Map<String, double> categoryTotals = {};
    for (var t in filtered) {
       categoryTotals.update(t.categoryId, (val) => val + t.amount, ifAbsent: () => t.amount);
    }
    
    // 3. Build Sections
    final total = categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    final sortedKeys = categoryTotals.keys.toList()..sort((a,b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));
    
    // Basic Color Palette
    final colors = [
       Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.brown
    ];
    
    return Row(
      children: [
        // Chart
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sortedKeys.asMap().entries.map((entry) {
                 final index = entry.key;
                 final category = entry.value;
                 final value = categoryTotals[category]!;
                 final percentage = (value / total) * 100;
                 final color = colors[index % colors.length];
                 
                 return PieChartSectionData(
                   color: color,
                   value: value,
                   title: '${percentage.toStringAsFixed(0)}%',
                   radius: 50,
                   titleStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                 );
              }).toList(),
            ),
          ),
        ),
        // Legend
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
               final category = sortedKeys[index];
               final color = colors[index % colors.length];
               return Padding(
                 padding: const EdgeInsets.symmetric(vertical: 4),
                 child: Row(
                   children: [
                     Container(width: 12, height: 12, color: color),
                     const SizedBox(width: 8),
                     Expanded(child: Text(category, style: GoogleFonts.outfit(fontSize: 12), overflow: TextOverflow.ellipsis)),
                   ],
                 ),
               );
            },
          ),
        ),
      ],
    );
  }
}
