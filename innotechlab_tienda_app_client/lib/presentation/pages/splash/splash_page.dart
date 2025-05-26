import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_tienda/presentation/providers/splash_provider.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndOnboardingStatus();
  }

  Future<void> _checkAuthAndOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading
    final provider = ref.read(splashProvider);
    final (isAuthenticated, onBoardingCompleted) = await provider.checkStatus();

    if (!onBoardingCompleted) {
      context.go('/onboarding');
    } else if (isAuthenticated) {
      context.go('/'); // Go to home if authenticated
    } else {
      context.go('/login'); // Go to login if not authenticated
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo
            Icon(
              Icons.shopping_bag,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Mi Tienda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}