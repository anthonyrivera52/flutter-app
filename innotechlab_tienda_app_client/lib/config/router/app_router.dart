import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/presentation/pages/splash/splash_page.dart';
import 'package:mi_tienda/presentation/pages/onboarding/onboarding_page.dart';
import 'package:mi_tienda/presentation/pages/auth/signin_page.dart';
import 'package:mi_tienda/presentation/pages/auth/signup_page.dart';
import 'package:mi_tienda/presentation/pages/home/home_page.dart';
import 'package:mi_tienda/presentation/pages/product_details/product_details_page.dart';
import 'package:mi_tienda/presentation/pages/cart/cart_page.dart';
import 'package:mi_tienda/presentation/pages/profile/profile_page.dart'; // Añadida
import 'package:mi_tienda/presentation/pages/notifications/notifications_page.dart'; // Añadida
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart'; // Para verificar onboarding
import 'package:mi_tienda/presentation/providers/auth_provider.dart';
import 'package:mi_tienda/service_locator.dart'; // Para acceder a cartLocalDataSourceProvider

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final cartLocalDataSource = ref.read(cartLocalDataSourceProvider);

  return GoRouter(
    initialLocation: '/splash', // Siempre empieza en splash
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'product/:productId',
            name: 'product_details',
            builder: (context, state) {
              final productId = state.pathParameters['productId']!;
              return ProductDetailsPage(productId: productId);
            },
          ),
          GoRoute(
            path: 'cart',
            name: 'cart',
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      // No redirigir si ya estamos en splash
      if (state.matchedLocation == '/splash') {
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;
      final onboardingCompleted = await cartLocalDataSource.isOnboardingCompleted();

      final goingToLogin = state.matchedLocation == '/signin';
      final goingToSignup = state.matchedLocation == '/signup';
      final goingToOnboarding = state.matchedLocation == '/onboarding';

      // Si el onboarding no está completo y no vamos a la página de onboarding, redirigir a onboarding
      if (!onboardingCompleted && !goingToOnboarding) {
        return '/onboarding';
      }

      // Si no está autenticado y no va a login/signup, redirigir a login
      if (!isAuthenticated && !goingToLogin && !goingToSignup) {
        return '/signin';
      }

      // Si está autenticado y tratando de ir a login/signup/onboarding, redirigir a home
      if (isAuthenticated && (goingToLogin || goingToSignup || goingToOnboarding)) {
        return '/';
      }

      // Si no hay redirección necesaria, permitir la navegación
      return null;
    },
  );
});