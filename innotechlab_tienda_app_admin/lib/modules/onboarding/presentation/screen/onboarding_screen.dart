import 'package:flutter/material.dart';
import 'package:flutter_app/modules/onboarding/presentation/viewmodel/onboarding_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenido al Onboarding'),
            ElevatedButton(
              onPressed: () async {
                await viewModel.completeOnboarding();
                context.go('/login');
              },
              child: const Text('Completar Onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}