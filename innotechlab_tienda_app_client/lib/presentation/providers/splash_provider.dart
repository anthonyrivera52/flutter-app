import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart'; // For onboarding status

final splashProvider = Provider<SplashProvider>((ref) {
  return SplashProvider(
    supabaseClient: Supabase.instance.client,
    cartLocalDataSource: ref.read(cartLocalDataSourceProvider),
  );
});

class SplashProvider {
  final SupabaseClient supabaseClient;
  final CartLocalDataSource cartLocalDataSource;

  SplashProvider({
    required this.supabaseClient,
    required this.cartLocalDataSource,
  });

  Future<(bool, bool)> checkStatus() async {
    final isAuthenticated = supabaseClient.auth.currentUser != null;
    final onBoardingCompleted = await cartLocalDataSource.isOnboardingCompleted();
    return (isAuthenticated, onBoardingCompleted);
  }
}