import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../constants/box_names.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/savings/domain/savings_goal.dart';
import '../../features/budget/domain/budget.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../../features/categories/domain/category.dart';
import '../../features/debt/domain/debt.dart';
import '../../features/bill_split/domain/bill_split.dart';
import '../../features/bill_split/domain/split_participant.dart';

final backupServiceProvider = Provider((ref) => BackupService());

class BackupService {
  Future<void> createBackup(BuildContext context) async {
    try {
      final data = <String, dynamic>{
        'version': 1, // Schema version
        'timestamp': DateTime.now().toIso8601String(),
        'accounts': _getBoxData(BoxNames.accounts),
        'transactions': _getBoxData(BoxNames.transactions),
        'savings': _getBoxData(BoxNames.savings),
        'budgets': _getBoxData(BoxNames.budgetBox),
        'recurring': _getBoxData(BoxNames.recurringBox),
        'debts': _getBoxData(BoxNames.debtsBox),
        'categories': _getBoxData(BoxNames.categoriesBox),
        'billSplits': _getBoxData(BoxNames.billSplitsBox),
        // Settings are typically local to device, but we can backup key ones if needed. 
        // Skipping generic settings box to avoid issues with specialized types or device-specific paths.
      };

      final jsonString = jsonEncode(data);
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/fintrack_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      final result = await Share.shareXFiles([XFile(file.path)], text: 'FinTrack Backup');
      
      if (result.status == ShareResultStatus.success) {
         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup shared successfully')));
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> restoreBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Basic Validation
      if (!data.containsKey('version') || !data.containsKey('accounts')) {
         throw Exception('Invalid backup file format');
      }

      // Restore Logic
      // 1. Clear existing data
      await _clearBox(BoxNames.accounts);
      await _clearBox(BoxNames.transactions);
      await _clearBox(BoxNames.savings);
      await _clearBox(BoxNames.budgetBox);
      await _clearBox(BoxNames.recurringBox);
      await _clearBox(BoxNames.debtsBox);
      await _clearBox(BoxNames.categoriesBox);
      await _clearBox(BoxNames.billSplitsBox);

      // 2. Populate new data
      // We need to decode dynamic maps back to HiveObjects if possible, 
      // OR since we are manually handling JSON, we might need manual fromJson?
      // Wait, Hive stores objects. jsonEncode calls toJson() if available.
      // But our HiveObjects represent strongly typed Dart objects.
      // Default jsonEncode might behave weirdly with HiveObjects unless they have toJson.
      // And standard HiveAdapters work with binaryWriter.
      
      // FIX: Since our entities might NOT have toJson/fromJson, we rely on Hive's TypeAdapters?
      // No, Hive TypeAdapters are for binary. For JSON export we need proper serialization.
      // Checking entities... Account, Transaction etc usually generated helper methods by some libs,
      // but here we likely only have Hive fields.
      
      // CRITICAL: We need toJson/fromJson for all entities for modification-free backup!
      // OR we can implement custom serialization here.
      // Given the constraints and likely missing toJson, I must implement mappers.
      
      // WAIT: Does `jsonEncode` work on arbitrary HiveObjects? Not automatically.
      // I will implement helper serialization inside this service to be safe.
      
      // Serialization Helpers
      await _restoreAccounts(data['accounts']);
      await _restoreTransactions(data['transactions']);
      await _restoreSavings(data['savings']);
      await _restoreBudgets(data['budgets']);
      await _restoreRecurring(data['recurring']);
      await _restoreDebts(data['debts']);
      await _restoreCategories(data['categories']);
      await _restoreBillSplits(data['billSplits']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore successful! Please restart app.')));
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }

  // --- Helpers ---

  List<Map<String, dynamic>> _getBoxData(String boxName) {
    if (!Hive.isBoxOpen(boxName)) return [];
    final box = Hive.box(boxName);
    return box.values.map((e) {
      // Reflection or manual casting? 
      // Manual casting is safer.
      if (e is Account) return _accountToJson(e);
      if (e is Transaction) return _transactionToJson(e);
      if (e is SavingsGoal) return _savingsToJson(e);
      if (e is Budget) return _budgetToJson(e);
      if (e is RecurringTransaction) return _recurringToJson(e);
      if (e is Debt) return _debtToJson(e);
      if (e is Category) return _categoryToJson(e);
      if (e is BillSplit) return _billSplitToJson(e);
      return <String, dynamic>{};
    }).toList();
  }

  Future<void> _clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
    }
  }

  // --- Mappers (ToJson) ---
  Map<String, dynamic> _accountToJson(Account a) => {
    'id': a.id, 'name': a.name, 'balance': a.balance, 'currencyCode': a.currencyCode, 'colorValue': a.colorValue, 'iconCode': a.iconCode
  };
  Map<String, dynamic> _transactionToJson(Transaction t) => {
    'id': t.id, 'amount': t.amount, 'currencyCode': t.currencyCode, 'categoryId': t.categoryId, 'accountId': t.accountId, 'date': t.date.toIso8601String(), 'note': t.note, 'type': t.type.name
  };
  Map<String, dynamic> _savingsToJson(SavingsGoal s) => {
    'id': s.id, 'name': s.name, 'targetAmount': s.targetAmount, 'savedAmount': s.savedAmount, 'iconCode': s.iconCode, 'colorValue': s.colorValue, 'currencyCode': s.currencyCode
  };
  Map<String, dynamic> _budgetToJson(Budget b) => {
    'id': b.id, 'categoryId': b.categoryId, 'amount': b.amount, 'period': b.period
  };
  Map<String, dynamic> _recurringToJson(RecurringTransaction r) => {
    'id': r.id, 'amount': r.amount, 'currencyCode': r.currencyCode, 'categoryId': r.categoryId, 'accountId': r.accountId, 'note': r.note, 'type': r.type.name, 'interval': r.interval, 'nextDueDate': r.nextDueDate.toIso8601String()
  };
  Map<String, dynamic> _debtToJson(Debt d) => {
    'id': d.id, 'personName': d.personName, 'amount': d.amount, 'date': d.date.toIso8601String(), 'dueDate': d.dueDate?.toIso8601String(), 'isLent': d.isLent, 'isSettled': d.isSettled, 'description': d.description
  };
  Map<String, dynamic> _categoryToJson(Category c) => {
    'id': c.id, 'name': c.name, 'iconCode': c.iconCode, 'colorValue': c.colorValue, 'type': c.type, 'isDefault': c.isDefault
  };
  Map<String, dynamic> _billSplitToJson(BillSplit b) => {
    'id': b.id, 'title': b.title, 'totalAmount': b.totalAmount, 'currencyCode': b.currencyCode, 'date': b.date.toIso8601String(),
    'participants': b.participants.map((p) => {'name': p.name, 'amount': p.amount, 'isPaid': p.isPaid, 'paidDate': p.paidDate?.toIso8601String()}).toList(),
    'myShare': b.myShare, 'transactionId': b.transactionId, 'receiptPath': b.receiptPath, 'note': b.note, 'createdAt': b.createdAt.toIso8601String()
  };

  // --- Restorers (FromJson) ---
  Future<void> _restoreAccounts(List<dynamic>? list) async {
    if (list == null) return;
    final box = Hive.box<Account>(BoxNames.accounts);
    for (var m in list) {
       final a = Account(
         id: m['id'], name: m['name'], balance: m['balance'], currencyCode: m['currencyCode'], colorValue: m['colorValue'], iconCode: m['iconCode']
       );
       await box.put(a.id, a);
    }
  }
  Future<void> _restoreTransactions(List<dynamic>? list) async {
      if (list == null) return;
      final box = Hive.box<Transaction>(BoxNames.transactions);
      for (var m in list) {
        final t = Transaction(
          id: m['id'], amount: m['amount'], currencyCode: m['currencyCode'], categoryId: m['categoryId'], accountId: m['accountId'], 
          date: DateTime.parse(m['date']), note: m['note'], 
          type: TransactionType.values.firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.expense)
        );
        await box.put(t.id, t);
      }
  }
  Future<void> _restoreSavings(List<dynamic>? list) async {
      if (list == null) return;
      final box = Hive.box<SavingsGoal>(BoxNames.savings);
      for (var m in list) {
          final s = SavingsGoal(
            id: m['id'], name: m['name'], targetAmount: m['targetAmount'], savedAmount: m['savedAmount'], iconCode: m['iconCode'], colorValue: m['colorValue'], currencyCode: m['currencyCode'] ?? 'USD'
          );
         await box.put(s.id, s);
      }
  }
  Future<void> _restoreBudgets(List<dynamic>? list) async {
      if (list == null) return;
      final box = Hive.box<Budget>(BoxNames.budgetBox);
      for (var m in list) {
         final b = Budget(id: m['id'], categoryId: m['categoryId'], amount: m['amount'], period: m['period']);
         await box.put(b.id, b);
      }
  }
  Future<void> _restoreRecurring(List<dynamic>? list) async {
      if (list == null) return;
      final box = Hive.box<RecurringTransaction>(BoxNames.recurringBox);
      for (var m in list) {
         final r = RecurringTransaction(
           id: m['id'], amount: m['amount'], currencyCode: m['currencyCode'], categoryId: m['categoryId'], accountId: m['accountId'], note: m['note'],
           type: TransactionType.values.firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.expense),
           interval: m['interval'], nextDueDate: DateTime.parse(m['nextDueDate'])
         );
         await box.put(r.id, r);
      }
  }
  Future<void> _restoreDebts(List<dynamic>? list) async {
      if (list == null) return;
      final box = Hive.box<Debt>(BoxNames.debtsBox);
      for (var m in list) {
         final d = Debt(
           id: m['id'], personName: m['personName'], amount: m['amount'], date: DateTime.parse(m['date']), 
           dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate']) : null, 
           isLent: m['isLent'], isSettled: m['isSettled'], description: m['description']
         );
         await box.put(d.id, d);
      }
  }
  Future<void> _restoreCategories(List<dynamic>? list) async {
      if (list == null) return;
      final box = Hive.box<Category>(BoxNames.categoriesBox);
      for (var m in list) {
         final c = Category(
           id: m['id'], name: m['name'], iconCode: m['iconCode'], colorValue: m['colorValue'], type: m['type'], isDefault: m['isDefault']
         );
         await box.put(c.id, c);
      }
  }
  Future<void> _restoreBillSplits(List<dynamic>? list) async {
      if (list == null) return;
      final box = Hive.box<BillSplit>(BoxNames.billSplitsBox);
      for (var m in list) {
         final participants = (m['participants'] as List<dynamic>).map((p) => SplitParticipant(
           name: p['name'],
           amount: p['amount'],
           isPaid: p['isPaid'],
           paidDate: p['paidDate'] != null ? DateTime.parse(p['paidDate']) : null,
         )).toList();
         final b = BillSplit(
           id: m['id'], title: m['title'], totalAmount: m['totalAmount'], currencyCode: m['currencyCode'],
           date: DateTime.parse(m['date']), participants: participants, myShare: m['myShare'],
           transactionId: m['transactionId'], receiptPath: m['receiptPath'], note: m['note'],
           createdAt: DateTime.parse(m['createdAt'])
         );
         await box.put(b.id, b);
      }
  }
}
