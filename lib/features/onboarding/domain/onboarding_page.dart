import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Predefined onboarding pages
class OnboardingPages {
  static const List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Welcome to FinTrack',
      description: 'Your personal finance companion. Track expenses, manage budgets, and achieve your financial goals.',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF10B981), // Emerald
    ),
    OnboardingPage(
      title: 'Powerful Features',
      description: 'Split bills, set savings goals, track debts, manage recurring transactions, and get detailed reports.',
      icon: Icons.auto_awesome,
      color: Color(0xFF8B5CF6), // Purple
    ),
    OnboardingPage(
      title: 'Get Started',
      description: 'Create your first account and start tracking your finances today. It only takes a minute!',
      icon: Icons.rocket_launch,
      color: Color(0xFFF59E0B), // Amber
    ),
  ];
}
