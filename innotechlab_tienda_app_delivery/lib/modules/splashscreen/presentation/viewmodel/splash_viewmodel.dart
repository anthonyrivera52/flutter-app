
import 'package:flutter_app/core/services/service_locator.dart';
import 'package:flutter_app/modules/auth/domain/usecase/check_login_status.dart';
import 'package:flutter_app/modules/auth/domain/usecase/get_user.dart';
import 'package:flutter_app/modules/onboarding/domain/usecase/check_onboarding_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashState {
  final String? nextRoute;

  SplashState({this.nextRoute});
}

class SplashViewModel extends StateNotifier<SplashState> {
  final CheckOnboardingStatus checkOnboardingStatus;
  final CheckLoginStatus checkLoginStatus;
  final GetUser getUser;

  SplashViewModel(this.checkOnboardingStatus, this.checkLoginStatus, this.getUser)
      : super(SplashState());

  Future<String> determineNextRoute() async {
    await Future.delayed(const Duration(seconds: 15)); // Splash de 15 segundos

    final isOnboardingCompleted = await checkOnboardingStatus();
    if (!isOnboardingCompleted) {
      state = SplashState(nextRoute: '/onboarding');
      return '/onboarding';
    }

    final isLoggedIn = await checkLoginStatus();
    if (!isLoggedIn) {
      state = SplashState(nextRoute: '/login');
      return '/login';
    }

    final user = await getUser();
    if (user == null) {
      state = SplashState(nextRoute: '/register');
      return '/register';
    }

    state = SplashState(nextRoute: '/dashboard');
    return '/dashboard';
  }
}

final splashViewModelProvider = StateNotifierProvider<SplashViewModel, SplashState>((ref) {
  return SplashViewModel(
    ref.read(checkOnboardingStatusProvider),
    ref.read(checkLoginStatusProvider),
    ref.read(getUserProvider),
  );
});