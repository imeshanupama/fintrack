import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';

class ReportService {
  Future<void> generateAndPrintPdf({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    
    // Sort transactions by date (descending)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    final balance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(startDate, endDate, dateFormat),
            pw.SizedBox(height: 20),
            _buildSummary(totalIncome, totalExpense, balance, currencyFormat),
            pw.SizedBox(height: 20),
            pw.Text("Transactions", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildTransactionTable(transactions, dateFormat, currencySymbol),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'fintrack_report_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}',
    );
  }

  pw.Widget _buildHeader(DateTime start, DateTime end, DateFormat fmt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('FinTrack Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text('Period: ${fmt.format(start)} - ${fmt.format(end)}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
      ],
    );
  }

  pw.Widget _buildSummary(double income, double expense, double balance, NumberFormat fmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Income', income, PdfColors.green700, fmt),
          _buildSummaryItem('Expense', expense, PdfColors.red700, fmt),
          _buildSummaryItem('Balance', balance, balance >= 0 ? PdfColors.green700 : PdfColors.red700, fmt),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, double amount, PdfColor color, NumberFormat fmt) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        pw.Text(fmt.format(amount), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  pw.Widget _buildTransactionTable(List<Transaction> transactions, DateFormat fmt, String currencySymbol) {
    return pw.Table.fromTextArray(
      headers: ['Date', 'Category', 'Note', 'Amount'],
      data: transactions.map((t) {
        final amountString = '${t.type == TransactionType.expense ? '-' : '+'}${currencySymbol}${t.amount.toStringAsFixed(2)}';
        // Simple capitalization
        final categoryName = t.categoryId.isNotEmpty 
            ? '${t.categoryId[0].toUpperCase()}${t.categoryId.substring(1)}' 
            : 'Uncategorized';
            
        return [
          fmt.format(t.date),
          categoryName,
          t.note,
          amountString,
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {3: pw.Alignment.centerRight},
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
    );
  }
}
