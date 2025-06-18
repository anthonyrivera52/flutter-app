import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreenPage extends ConsumerStatefulWidget {
  const SplashScreenPage({super.key});

  @override
  ConsumerState<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends ConsumerState<SplashScreenPage> {  

    @override
    void initState() {
      super.initState();
      _navigateToNextScreen();
    }
    
    Future<void> _navigateToNextScreen() async {
      await Future.delayed(const Duration(seconds: 10)); // Simulate a splash screen delay
      context.go('/onboarding'); // Navigate to the onboarding page
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

            colors: [Color.fromARGB(255, 255, 255, 255),Color.fromARGB(255, 255, 255, 255),]
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
                const SizedBox(
                  height: 180.0,
                ),
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
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.black54,
                      ),
                    ),
             SizedBox(height: 50.0),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
            SizedBox(height: 10.0),
            Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black54,
              ),
            ),
                  ],
                ),
              ],
            ),
          ],
        )
      )
    );
  }
}

