import 'package:flutter_app/presentation/pages/auth/OTP/opt_verification_page.dart';
import 'package:flutter_app/presentation/pages/auth/signIn/sing_in_page.dart';
import 'package:flutter_app/presentation/pages/auth/singUp/sing_up_page.dart';
import 'package:flutter_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:flutter_app/presentation/pages/dashboard/profile/profile.dart';
import 'package:flutter_app/presentation/pages/products/detail_page.dart';
import 'package:flutter_app/presentation/pages/onboarding/onboarding_page.dart';
import 'package:flutter_app/presentation/pages/products/product_list_page.dart';
import 'package:flutter_app/presentation/pages/splash_screen/splash_screen_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Necesario para usar Provider en el router

/// Proveedor de GoRouter para la configuración de rutas de la aplicación.
/// Este proveedor es accesible globalmente para la navegación.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // La ruta inicial de la aplicación.
    initialLocation: '/splash_screen',
    routes: [
      // Ruta para la página de inicio
      GoRoute(
        path: '/splash_screen',
        name: 'splash_screen', // Nombre opcional para referenciar la ruta
        builder: (context, state) => const SplashScreenPage(), // Cambia esto a tu página de splash
      ),
      // Ruta para la página de onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding', // Nombre opcional para referenciar la ruta
        builder: (context, state) => const OnboardingPage(), // Cambia esto a tu página de onboarding
      ),
      GoRoute(
        path: '/signin',
        name: 'signin', // Nombre opcional para referenciar la ruta
        builder: (context, state) => const SignInPage(),
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
        name: 'dashboard', // Nombre opcional para referenciar la ruta
        builder: (context, state) {
          int? initialTabIndex;
          if (state.extra is Map<String, dynamic>) {
            initialTabIndex = (state.extra as Map<String, dynamic>)['initialTabIndex'] as int?;
          }
          return DashboardPage(initialTabIndex: initialTabIndex);
        },
        routes: [
          // Ruta para la pestaña de perfil dentro del dashboard
          GoRoute(
            path: 'profile',
            name: 'profile', // Nombre opcional para referenciar la ruta
            builder: (context, state) => const ProfilePage(), // Cambia esto a tu página de perfil
          ),
          // Ruta para la página de detalles de producto (ejemplo)
          GoRoute(
            path: 'product/:productId', // Asumo que tienes una ruta de detalle de producto
            name: 'product_detail',
            builder: (context, state) {
              final productId = state.pathParameters['productId']!;
              // Aquí deberías pasar el productId a tu ProductDetailPage
              return ProductDetailsPage(productId: productId); // Ejemplo: ProductDetailPage recibe productId
            },
          ),
          // Ruta para la página de lista de productos por categoría o tipo
          GoRoute(
            path: 'products/:categoryId/:categoryName', // Rutas con parámetros
            name: 'product_list', // Nombre para una navegación más fácil
            builder: (context, state) {
              final categoryId = state.pathParameters['categoryId']!;
              final categoryName = state.pathParameters['categoryName']!;
              return ProductListPage(
                categoryId: categoryId,
                categoryName: categoryName,
              );
            },
          ),
        ],
      ),
      // Puedes añadir más rutas aquí según sea necesario
    ],
    // Puedes añadir un manejador de errores o redirecciones aquí si lo necesitas
    // errorBuilder: (context, state) => const Text('Error de ruta'),
  );
});
