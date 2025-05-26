// lib/presentation/pages/onboarding/onboarding_page.dart (Ejemplo conceptual)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_button.dart';
import 'package:mi_tienda/presentation/widgets/onboarding_indicator.dart'; // NUEVO

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/onboarding/onboarding1.png',
      'title': 'Explora Productos',
      'description': 'Descubre una amplia variedad de productos de calidad.',
    },
    {
      'image': 'assets/onboarding/onboarding2.png',
      'title': 'Compra Fácil',
      'description': 'Proceso de compra simple y seguro en pocos pasos.',
    },
    {
      'image': 'assets/onboarding/onboarding3.png',
      'title': 'Entrega Rápida',
      'description': 'Recibe tus productos directamente en tu puerta.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                final data = _onboardingData[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      data['image']!,
                      height: 250,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      data['title']!,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        data['description']!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          OnboardingIndicator( // Aquí se usa el indicador
            count: _onboardingData.length,
            currentIndex: _currentPage,
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: CustomButton(
              text: _currentPage == _onboardingData.length - 1 ? 'Empezar' : 'Siguiente',
              onPressed: () async {
                if (_currentPage == _onboardingData.length - 1) {
                  // Marcar onboarding como completado
                  // Puedes usar ref.read(cartLocalDataSourceProvider).setOnboardingStatus(true);
                  context.go('/login'); // Ir a la página de login
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}