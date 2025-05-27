import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_tienda/presentation/providers/auth_provider.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart'; // Para verificar onboarding
import 'package:mi_tienda/service_locator.dart'; // Para acceder a cartLocalDataSourceProvider

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Espera un breve momento para mostrar el splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    final cartLocalDataSource = ref.read(cartLocalDataSourceProvider);
    final onboardingCompleted = await cartLocalDataSource.isOnboardingCompleted();

    if (!onboardingCompleted) {
      context.go('/onboarding');
    } else if (authState.isAuthenticated) {
      context.go('/'); // Si está autenticado y onboarding completo, ir a Home
    } else {
      context.go('/signin'); // Si no está autenticado y onboarding completo, ir a SignIn
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Puedes añadir un logo o un CircularProgressIndicator aquí
            FlutterLogo(size: 100),
            SizedBox(height: 20),
            Text(
              'Mi Tienda MVP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
