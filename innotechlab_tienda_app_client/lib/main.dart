import 'package:flutter/material.dart';
import 'package:flutter_app/config/constants/app_constats.dart';
import 'package:flutter_app/config/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Importa geolocator

// Función para solicitar permisos de ubicación
Future<void> _requestLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Verifica si los servicios de ubicación están habilitados.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Los servicios de ubicación no están habilitados.
    // Considera mostrar un mensaje al usuario o abrir la configuración.
    print('Servicios de ubicación deshabilitados.');
    // Geolocator.openLocationSettings(); // Podrías abrir la configuración de ubicación directamente
    return;
  }

  // Comprueba el estado actual de los permisos de ubicación.
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // Los permisos están denegados, solicita al usuario.
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Los permisos siguen denegados después de la solicitud.
      print('Permiso de ubicación denegado por el usuario.');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Los permisos están denegados permanentemente, no se puede solicitar de nuevo.
    // Debes dirigir al usuario a la configuración de la aplicación.
    print('Permiso de ubicación denegado permanentemente.');
    // Geolocator.openAppSettings(); // Podrías abrir la configuración de la app directamente
    return;
  }

  // Si llegamos aquí, los permisos están concedidos (o granted, o whileInUse)
  print('Permiso de ubicación concedido.');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solicita los permisos de geolocalización al iniciar la aplicación
  await _requestLocationPermission();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl, // <-- ¡REEMPLAZA CON TU URL DE SUPABASE!
    anonKey: AppConstants.supabaseAnonKey, // <-- ¡REEMPLAZA CON TU ANON KEY DE SUPABASE!
  );

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa el proveedor del router para obtener la configuración
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router( // Cambiado a MaterialApp.router
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: appRouter, // Asigna la configuración del router aquí
    );
  }
}
