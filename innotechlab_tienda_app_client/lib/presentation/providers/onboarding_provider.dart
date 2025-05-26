import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart';
import 'package:mi_tienda/service_locator.dart';

final onboardingProvider = Provider<OnboardingProvider>((ref) {
  return OnboardingProvider(
    cartLocalDataSource: ref.read(cartLocalDataSourceProvider),
  );
});

class OnboardingProvider {
  final CartLocalDataSource cartLocalDataSource;

  OnboardingProvider({required this.cartLocalDataSource});

  Future<void> completeOnboarding() async {
    await cartLocalDataSource.setOnboardingCompleted(true);
  }
}