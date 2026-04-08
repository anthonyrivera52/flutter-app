import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/presentation/provider/onboarding_provider.dart';
import 'package:flutter_app/presentation/provider/preloaded_location_provider.dart';
import 'package:flutter_app/presentation/provider/region_provider.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreenPage extends ConsumerStatefulWidget {
  const SplashScreenPage({super.key});

  @override
  ConsumerState<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends ConsumerState<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    await ref.read(regionProvider.notifier).initialize();

    // Check GPS in background without blocking (fire and forget)
    ref.read(regionProvider.notifier).checkAndUpdateFromGPS();

    // Pre-load location during splash (non-blocking)
    final locationFuture = _preloadLocation();

    // Wait 15 seconds for map + info to load in background
    await Future.delayed(const Duration(seconds: 15));
    await locationFuture;

    final storage = ref.read(keyValueStorageProvider);
    final onboardingCompleted = await storage.isOnboardingCompleted();

    if (!mounted) return;

    if (!onboardingCompleted) {
      context.go('/onboarding');
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted) return;

    if (session != null) {
      context.go('/');
    } else {
      context.go('/signin');
    }
  }

  Future<void> _preloadLocation() async {
    try {
      final locationService = LocationService();
      final result = await locationService.getCurrentPosition(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 12),
        maxRetries: 1,
      );
      ref.read(preloadedLocationProvider.notifier).state = result;
    } catch (_) {
      // Silently fail — home page will try again
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,

            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Image.asset(
                  'assets/images/splash_screen_page.jpg',
                  width: 300.0,
                  height: 300.0,
                ),
                const SizedBox(height: 180.0),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Bienvenido a la App',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      'Tu aplicación de pedidos a domicilio',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0, color: Colors.black54),
                    ),
                    SizedBox(height: 50.0),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      'Cargando...',
                      style: TextStyle(fontSize: 16.0, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
