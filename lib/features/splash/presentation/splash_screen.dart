import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuth();
      }
    });
  }

  void _checkAuth() {
    // Auth logic is handled by router redirect usually, but since we are manually here:
    // We can just rely on the router to redirect us away from /splash if we navigate to /
    // But better:
    final authState = ref.read(authStateProvider);
    if (authState.value != null) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E), // Match Logo Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              width: 150,
              height: 150,
            )
            .animate()
            .fade(duration: 800.ms)
            .scale(delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 24),
            
            const CircularProgressIndicator(color: Colors.white)
            .animate()
            .fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
