import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(FirebaseFirestore.instance, FirebaseAuth.instance);
});
