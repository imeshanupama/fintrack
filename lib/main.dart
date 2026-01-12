import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/box_names.dart';
import 'features/accounts/domain/account.dart';
import 'features/transactions/domain/transaction.dart';
import 'features/transactions/domain/transaction_type.dart';
import 'features/savings/domain/savings_goal.dart';
import 'features/budget/domain/budget.dart';
import 'features/recurring/domain/recurring_transaction.dart';

import 'features/recurring/domain/recurring_transaction.dart';
import 'features/categories/domain/category.dart';
import 'features/debt/domain/debt.dart'; // Import Debt entity
import 'core/router/app_router.dart';
import 'features/settings/presentation/settings_provider.dart'; // To listen to theme changes

import 'features/security/data/biometric_service.dart';
import 'core/sync/sync_manager.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Hive
    await Hive.initFlutter();

    // Initialize Firebase
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
    
    // Register Adapters
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(SavingsGoalAdapter());
    Hive.registerAdapter(BudgetAdapter());

    Hive.registerAdapter(RecurringTransactionAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(DebtAdapter()); // Register Debt Adapter

    // Open Boxes
    await Hive.openBox<Account>(BoxNames.accounts);
    await Hive.openBox<Transaction>(BoxNames.transactions);
    await Hive.openBox<SavingsGoal>(BoxNames.savings);
    await Hive.openBox<Budget>(BoxNames.budgetBox);

    await Hive.openBox<RecurringTransaction>(BoxNames.recurringBox);
    await Hive.openBox<Category>(BoxNames.categoriesBox);
    await Hive.openBox<Debt>(BoxNames.debtsBox); // Open Debt Box
    
    // Open Settings Box
    await Hive.openBox(BoxNames.settings); // Generic box for settings

    // Initialize Notifications
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint("Notification initialization failed: $e");
    }

    runApp(const ProviderScope(child: SyncManager(child: MyApp())));
  } catch (e, stack) {
    debugPrint("CRITICAL STARTUP ERROR: $e\n$stack");
    runApp(ErrorApp(error: e.toString(), stack: stack.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String stack;
  const ErrorApp({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                "App Failed to Start",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text("Please send this screenshot to support:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(
                error,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text("Stack Trace:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(
                stack,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _isAuthenticated = true;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check initial state after first frame to avoid provider race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (settings.isBiometricsEnabled) {
         setState(() {
           _isAuthenticated = false;
         });
         _authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (ref.read(settingsProvider).isBiometricsEnabled) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (ref.read(settingsProvider).isBiometricsEnabled && !_isAuthenticated) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    try {
      final success = await ref.read(biometricServiceProvider).authenticate();
      if (success && mounted) {
        setState(() {
           _isAuthenticated = true;
        });
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(goRouterProvider);

    if (settings.isBiometricsEnabled && !_isAuthenticated) {
       return MaterialApp(
         debugShowCheckedModeBanner: false,
         theme: AppTheme.lightTheme,
         darkTheme: AppTheme.darkTheme,
         themeMode: settings.themeMode,
         home: Scaffold(
           body: Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                 const SizedBox(height: 24),
                 const Text('App Locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 24),
                 FilledButton.icon(
                   onPressed: _authenticate,
                   icon: const Icon(Icons.fingerprint),
                   label: const Text('Unlock'),
                 ),
               ],
             ),
           ),
         ),
       );
    }
    
    return MaterialApp.router(
      routerConfig: router,
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
    );
  }
}
