import 'package:flutter_app/features/auth/presentation/views/otp_verification_page.dart';
import 'package:flutter_app/features/auth/presentation/views/sign_in_page.dart';
import 'package:flutter_app/features/auth/presentation/views/sign_up_page.dart';
import 'package:flutter_app/features/orders/presentation/views/order_details_page.dart';
import 'package:flutter_app/features/orders/presentation/views/orders_list_page.dart';
import 'package:flutter_app/features/profile/presentation/views/profile_page.dart';
import 'package:flutter_app/features/products/presentation/views/product_detail_page.dart';
import 'package:flutter_app/features/products/presentation/views/product_list_page.dart';
import 'package:flutter_app/presentation/pages/cart/cart_page.dart';
import 'package:flutter_app/presentation/pages/checkout/checkout_page.dart';
import 'package:flutter_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:flutter_app/presentation/pages/location/location_selection_page.dart';
import 'package:flutter_app/presentation/pages/notifications/notifications_page.dart';
import 'package:flutter_app/presentation/pages/onboarding/onboarding_page.dart';
import 'package:flutter_app/presentation/pages/order_confirmation/order_confirmation_page.dart';
import 'package:flutter_app/presentation/pages/splash_screen/splash_screen_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash_screen',
    routes: [
      GoRoute(
        path: '/splash_screen',
        name: 'splash_screen',
        builder: (_, __) => const SplashScreenPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (_, __) => const SignInPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignUpPage(),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otp_verification',
        builder: (_, state) =>
            OtpVerificationPage(email: state.extra as String?),
      ),
      GoRoute(
        path: '/location-selection',
        name: 'location_selection',
        builder: (_, __) => const LocationSelectionPage(),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (_, state) {
          int? initialTabIndex;
          if (state.extra is Map<String, dynamic>) {
            initialTabIndex =
                (state.extra as Map<String, dynamic>)['initialTabIndex']
                    as int?;
          }
          return DashboardPage(initialTabIndex: initialTabIndex);
        },
        routes: [
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: 'product/:productId',
            name: 'product_detail',
            builder: (_, state) => ProductDetailsPage(
              productId: state.pathParameters['productId']!,
            ),
          ),
          GoRoute(
            path: 'products/:categoryId/:categoryName',
            name: 'product_list',
            builder: (_, state) => ProductListPage(
              categoryId: state.pathParameters['categoryId']!,
              categoryName: state.pathParameters['categoryName']!,
            ),
          ),
          GoRoute(
            path: 'cart',
            name: 'cart',
            builder: (_, __) => const CartModalContent(),
          ),
          GoRoute(
            path: 'checkout',
            name: 'checkout',
            builder: (_, __) => CheckoutPageModal(),
          ),
          GoRoute(
            path: 'order-confirmation',
            name: 'order_confirmation',
            builder: (_, __) => OrderConfirmationPage(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (_, __) => const NotificationsPage(),
          ),
          GoRoute(
            path: 'order-list',
            name: 'order',
            builder: (_, __) => const OrdersListPage(),
          ),
          GoRoute(
            path: 'order-details/:orderId',
            name: 'order_details',
            builder: (_, state) => OrderDetailsPage(
              orderId: state.pathParameters['orderId']!,
            ),
          ),
        ],
      ),
    ],
  );
});
