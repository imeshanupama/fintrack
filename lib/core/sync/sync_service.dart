import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../constants/box_names.dart';

class SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _recurringSub;

  SyncService(this._firestore, this._auth);

  String? get _userId => _auth.currentUser?.uid;

  // Initialize Sync
  Future<void> init() async {
    if (_userId == null) return;

    // 1. Listen to Firestore changes (Remote -> Local)
    _listenToRemoteAccounts();
    _listenToRemoteTransactions();
    _listenToRemoteRecurring();

    // 2. Listen to Hive changes (Local -> Remote)
    _listenToLocalChanges();
  }

  void dispose() {
    _accountsSub?.cancel();
    _transactionsSub?.cancel();
    _recurringSub?.cancel();
  }

  // --- Remote -> Local ---

  void _listenToRemoteAccounts() {
    if (_userId == null) return;
    _accountsSub = _firestore
        .collection('users')
        .doc(_userId)
        .collection('accounts')
        .snapshots()
        .listen((snapshot) async {
      final box = Hive.box<Account>(BoxNames.accounts); // Corrected Box Name
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final account = Account.fromJson(data);
             // Avoid infinite loop: Check if local matches remote
            final local = box.get(account.id);
            if (local == null) {
               await box.put(account.id, account);
            } else {
               // Only update if different? Ideally yes.
               // For now, simpler to overwrite to enforce sync.
               // But compare fields to be safe if desired.
               await box.put(account.id, account);
            }
          }
        } else if (change.type == DocumentChangeType.removed) {
          final id = change.doc.id;
          if (box.containsKey(id)) {
            await box.delete(id);
          }
        }
      }
    });
  }

  void _listenToRemoteTransactions() {
    if (_userId == null) return;
    _transactionsSub = _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .snapshots()
        .listen((snapshot) async {
      final box = Hive.box<Transaction>(BoxNames.transactions);
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final transaction = Transaction.fromJson(data);
            await box.put(transaction.id, transaction);
          }
        } else if (change.type == DocumentChangeType.removed) {
          final id = change.doc.id;
          if (box.containsKey(id)) {
            await box.delete(id);
          }
        }
      }
    });
  }

   void _listenToRemoteRecurring() {
    if (_userId == null) return;
    _recurringSub = _firestore
        .collection('users')
        .doc(_userId)
        .collection('recurring')
        .snapshots()
        .listen((snapshot) async {
      final box = Hive.box<RecurringTransaction>(BoxNames.recurringBox);
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final recurring = RecurringTransaction.fromJson(data);
            await box.put(recurring.id, recurring);
          }
        } else if (change.type == DocumentChangeType.removed) {
          final id = change.doc.id;
          if (box.containsKey(id)) {
            await box.delete(id);
          }
        }
      }
    });
  }


  // --- Local -> Remote ---

  void _listenToLocalChanges() {
    // Watch Account Box
    final accountBox = Hive.box<Account>(BoxNames.accounts);
    accountBox.watch().listen((event) {
      if (_userId == null) return;
      if (event.deleted) {
        _firestore.collection('users').doc(_userId).collection('accounts').doc(event.key.toString()).delete();
      } else {
        final Account? account = accountBox.get(event.key);
        if (account != null) {
          _firestore.collection('users').doc(_userId).collection('accounts').doc(account.id).set(account.toJson());
        }
      }
    });

    // Watch Transaction Box
    final txBox = Hive.box<Transaction>(BoxNames.transactions);
    txBox.watch().listen((event) {
      if (_userId == null) return;
      if (event.deleted) {
         _firestore.collection('users').doc(_userId).collection('transactions').doc(event.key.toString()).delete();
      } else {
        final Transaction? tx = txBox.get(event.key);
        if (tx != null) {
           _firestore.collection('users').doc(_userId).collection('transactions').doc(tx.id).set(tx.toJson());
        }
      }
    });
    
    // Watch Recurring Box
    final recBox = Hive.box<RecurringTransaction>(BoxNames.recurringBox);
    recBox.watch().listen((event) {
      if (_userId == null) return;
      if (event.deleted) {
         _firestore.collection('users').doc(_userId).collection('recurring').doc(event.key.toString()).delete();
      } else {
        final RecurringTransaction? rec = recBox.get(event.key);
        if (rec != null) {
           _firestore.collection('users').doc(_userId).collection('recurring').doc(rec.id).set(rec.toJson());
        }
      }
    });
  }

  // Manual Full Sync (Optional, good for initial load)
  Future<void> syncAllLocalToRemote() async {
     if (_userId == null) return;
     
     final accountBox = Hive.box<Account>(BoxNames.accounts);
     for (var account in accountBox.values) {
        await _firestore.collection('users').doc(_userId).collection('accounts').doc(account.id).set(account.toJson());
     }
     
     final txBox = Hive.box<Transaction>(BoxNames.transactions);
     for (var tx in txBox.values) {
        await _firestore.collection('users').doc(_userId).collection('transactions').doc(tx.id).set(tx.toJson());
     }
     
     final recBox = Hive.box<RecurringTransaction>(BoxNames.recurringBox);
     for (var rec in recBox.values) {
        await _firestore.collection('users').doc(_userId).collection('recurring').doc(rec.id).set(rec.toJson());
     }
  }
}
