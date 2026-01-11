import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_provider.dart';
import 'sync_provider.dart';

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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      final syncService = ref.read(syncServiceProvider);
      
      if (user != null) {
        debugPrint("User logged in. Initializing Sync.");
        syncService.init();
      } else {
        debugPrint("User logged out. Disposing Sync.");
        syncService.dispose();
      }
    });
    
    return widget.child;
  }
}
