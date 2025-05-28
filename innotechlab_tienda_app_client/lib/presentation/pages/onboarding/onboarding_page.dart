import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/onboarding_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      'image': 'assets/images/onboarding1.png', // Asegúrate de tener estas imágenes
      'title': 'Explora Productos',
      'description': 'Descubre una amplia variedad de productos de calidad.',
    },
    {
      'image': 'assets/images/onboarding2.png',
      'title': 'Compra Fácil y Segura',
      'description': 'Proceso de compra simple y seguro en pocos pasos.',
    },
    {
      'image': 'assets/images/onboarding3.png',
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

  void _completeOnboarding() async {
    // final cartLocalDataSource = ref.read(cartLocalDataSourceProvider);
    // await cartLocalDataSource.setOnboardingCompleted(true);
    // if (mounted) {
    //   context.go('/signin'); // Redirigir a la página de inicio de sesión
    // }

    // context.go('/signin'); // Redirigir a la página de inicio de sesión
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final data = _onboardingData[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Asegúrate de que las imágenes existan en assets/images/
                    Image.asset(
                      data['image']!,
                      height: 250,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100, color: AppColors.greyMedium),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textLightColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          OnboardingIndicator(
            count: _onboardingData.length,
            currentIndex: _currentPage,
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: CustomButton(
              text: _currentPage == _onboardingData.length - 1 ? 'Empezar' : 'Siguiente',
              onPressed: () {
                if (_currentPage == _onboardingData.length - 1) {
                  _completeOnboarding();
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