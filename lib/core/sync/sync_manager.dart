import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_provider.dart';
import 'sync_provider.dart';
import '../../features/recurring/application/recurring_transaction_service.dart';

class SyncManager extends ConsumerStatefulWidget {
  final Widget child;
  const SyncManager({super.key, required this.child});

  @override
  ConsumerState<SyncManager> createState() => _SyncManagerState();
}

class _SyncManagerState extends ConsumerState<SyncManager> {
  @override
  void initState() {
    super.initState();
    // Initialize if already logged in on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
         ref.read(syncServiceProvider).init();
         ref.read(recurringTransactionServiceProvider).checkAndGenerateTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      final syncService = ref.read(syncServiceProvider);
      final recurringService = ref.read(recurringTransactionServiceProvider);
      
      if (user != null) {
        debugPrint("User logged in. Initializing Sync & Recurring.");
        syncService.init();
        recurringService.checkAndGenerateTransactions();
      } else {
        debugPrint("User logged out. Disposing Sync.");
        syncService.dispose();
      }
    });
    
    return widget.child;
  }
}
