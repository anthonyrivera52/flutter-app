import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart';
import 'package:mi_tienda/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/presentation/pages/splash/splash_page.dart';
import 'package:mi_tienda/presentation/pages/onboarding/onboarding_page.dart';
import 'package:mi_tienda/presentation/pages/auth/login_page.dart';
import 'package:mi_tienda/presentation/pages/auth/signup_page.dart';
import 'package:mi_tienda/presentation/pages/auth/otp_verification_page.dart'; // NUEVO
// Import the new DashboardPage
import 'package:mi_tienda/presentation/pages/dashboard/dashboard_page.dart';
// HomePage is no longer the direct target for '/', HomeTabPageContent is used by DashboardPage
// import 'package:mi_tienda/presentation/pages/home/home_page.dart'; 
import 'package:mi_tienda/presentation/pages/product_details/product_details_page.dart';
import 'package:mi_tienda/presentation/pages/cart/cart_page.dart';
import 'package:mi_tienda/presentation/pages/checkout/checkout_page.dart';
import 'package:mi_tienda/presentation/pages/order_confirmation/order_confirmation_page.dart';
import 'package:mi_tienda/presentation/pages/notifications/notifications_page.dart';
import 'package:mi_tienda/presentation/pages/profile/profile_page.dart'; // NUEVO
// Import for OrderDetailsPage
import 'package:mi_tienda/presentation/pages/orders/order_details_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) { // Renamed to appRouterProvider
  final supabase = Supabase.instance.client;
  final cartLocalDataSource = CartLocalDataSource(sharedPreferences: ref.read(sharedPreferencesProvider));

  return GoRouter(
    initialLocation: '/splash',
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
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otp_verification',
        builder: (context, state) => OtpVerificationPage(email: state.extra as String?),
      ),
      GoRoute(
        path: '/',
        name: 'home', // Or rename to 'dashboard' if more appropriate
        builder: (context, state) {
          int? initialTabIndex;
          if (state.extra is Map<String, dynamic>) {
            initialTabIndex = (state.extra as Map<String, dynamic>)['initialTabIndex'] as int?;
          }
          return DashboardPage(initialTabIndex: initialTabIndex);
        },
        routes: [
          // Product details can be a sub-route of the home tab's content
          GoRoute(
            path: 'product/:id',
            name: 'product_details',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              return ProductDetailsPage(productId: productId);
            },
          ),
          GoRoute(
            path: 'cart',
            name: 'cart',
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: 'checkout',
            name: 'checkout',
            builder: (context, state) => const CheckoutPage(),
          ),
          GoRoute(
            path: 'order-confirmation',
            name: 'order_confirmation',
            builder: (context, state) => const OrderConfirmationPage(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          // New route for OrderDetailsPage
          GoRoute(
            path: 'order-details/:orderId',
            name: 'order_details',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return OrderDetailsPage(orderId: orderId);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final loggedIn = supabase.auth.currentUser != null;
      final onBoardingCompleted = await cartLocalDataSource.isOnboardingCompleted(); // Corrected method name

      final goingToLogin = state.matchedLocation == '/login';
      final goingToSignup = state.matchedLocation == '/signup';
      final goingToSplash = state.matchedLocation == '/splash';
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      final goingToOtpVerification = state.matchedLocation == '/otp-verification';

      // Si está en Splash, deja que cargue y maneje su propia redirección
      if (goingToSplash) return null;

      // Si el onboarding no está completo, ir a la página de onboarding
      if (!onBoardingCompleted && !goingToOnboarding) {
        return '/onboarding';
      }

      // Si no está logueado y no va a login/signup/onboarding/otp, redirigir a login
      if (!loggedIn && !goingToLogin && !goingToSignup && !goingToOnboarding && !goingToOtpVerification) {
        return '/login';
      }

      // Si está logueado y tratando de ir a login/signup, redirigir a home
      if (loggedIn && (goingToLogin || goingToSignup)) {
        return '/';
      }

      // Lógica de OTP:
      // Si el usuario está logueado pero su email no está confirmado (y no está en la página de OTP),
      // lo redirigimos a la página de OTP para que verifique.
      if (loggedIn && !goingToOtpVerification && supabase.auth.currentUser?.emailConfirmedAt == null) {
         return '/otp-verification';
      }

      return null; // No redirection needed
    },
  );
});