import 'package:flutter_app/core/constants/flavors.dart';
import 'package:flutter_app/modules/auth/presentation/screen/login_screen.dart';
import 'package:flutter_app/modules/auth/presentation/screen/register_screen.dart';
import 'package:flutter_app/modules/onboarding/presentation/screen/onboarding_screen.dart';
import 'package:flutter_app/modules/splashscreen/presentation/screen/splash_screen.dart';
import 'package:flutter_app/modules/splashscreen/presentation/viewmodel/splash_viewmodel.dart';
import 'package:flutter_app/widget/tab_clientordelivery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


final routerProvider = Provider<GoRouter>((ref) { 
  final splashViewModel = ref.watch(splashViewModelProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen()
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const ClientOrDeliveryDashboard(),
      ),
    ],
    redirect: (context, state) async {
      if (state.uri.toString() == '/splash') {
        final route = await splashViewModel.determineNextRoute();
        return route;
      }
      return null;
    },
 );
}

);
