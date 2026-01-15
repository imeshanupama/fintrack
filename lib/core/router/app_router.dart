import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/savings/domain/savings_goal.dart';
import '../../features/budget/domain/budget.dart';
import '../../features/accounts/presentation/screens/add_account_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/analytics/presentation/calendar_screen.dart';
import '../../features/savings/presentation/savings_screen.dart';
import '../../features/savings/presentation/screens/add_savings_goal_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/budget/presentation/add_budget_screen.dart';
import '../../features/reports/presentation/screens/report_screen.dart';
import '../../features/debt/presentation/debt_screen.dart';
import '../../features/debt/presentation/add_debt_screen.dart';
import '../../features/bill_split/presentation/bill_split_screen.dart';
import '../../features/categories/presentation/manage_categories_screen.dart';
import '../../features/settings/data/settings_repository.dart'; // Import SettingsRepository
import '../../features/onboarding/presentation/onboarding_screen.dart'; // Import OnboardingScreen

import '../../features/splash/presentation/splash_screen.dart';
import '../widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final settingsRepo = ref.read(settingsRepositoryProvider); // Read Settings Repo

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      final isAuthenticated = authState.asData?.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';
      final isSplash = state.uri.toString() == '/splash';
      final isOnboarding = state.uri.toString() == '/onboarding';

      // Always allow splash
      if (isSplash) return null;

      if (!isAuthenticated && !isLoggingIn && !isSigningUp) {
        return '/login';
      }

      if (isAuthenticated) {
        if (isLoggingIn || isSigningUp) {
          return '/';
        }

        // Onboarding Check
        final hasCompletedOnboarding = settingsRepo.getHasCompletedOnboarding();
        if (!hasCompletedOnboarding && !isOnboarding) {
          return '/onboarding';
        }
        if (hasCompletedOnboarding && isOnboarding) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/savings',
            builder: (context, state) => const SavingsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetScreen(),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add-account',
        builder: (context, state) {
          final account = state.extra as Account?;
          return AddAccountScreen(account: account);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add-transaction',
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          return AddTransactionScreen(transaction: transaction);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add-savings-goal',
        builder: (context, state) {
           final goal = state.extra as SavingsGoal?;
           return AddSavingsGoalScreen(goal: goal);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add-budget',
        builder: (context, state) {
          final budget = state.extra as Budget?;
          return AddBudgetScreen(budget: budget);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reports',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/manage-categories',
        builder: (context, state) => const ManageCategoriesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/debt',
        builder: (context, state) => const DebtScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add-debt',
        builder: (context, state) => const AddDebtScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/bill-split',
        builder: (context, state) => const BillSplitScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
