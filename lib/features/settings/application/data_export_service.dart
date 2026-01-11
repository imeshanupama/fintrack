import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';

final dataExportServiceProvider = Provider<DataExportService>((ref) {
  final transactionRepo = ref.read(transactionRepositoryProvider);
  return DataExportService(transactionRepo);
});

class DataExportService {
  final TransactionRepository _transactionRepository;

  DataExportService(this._transactionRepository);

  Future<void> exportTransactionsToCsv() async {
    // 1. Fetch all transactions
    final transactions = _transactionRepository.getAll();
    
    // 2. Convert to List<List<dynamic>> for CSV
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'Date',
      'Type',
      'Category',
      'Amount',
      'Currency',
      'Note',
      'Account ID'
    ]);

    // Data
    for (var tx in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(tx.date),
        tx.type == TransactionType.income ? 'Income' : 'Expense',
        tx.categoryId, // Ideally category name from ID
        tx.amount,
        tx.currencyCode,
        tx.note,
        tx.accountId
      ]);
    }

    // 3. Convert to CSV string
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Write to file
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/transactions_export.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    // 5. Share file
    await Share.shareXFiles([XFile(path)], text: 'My Transactions Export');
  }
}
