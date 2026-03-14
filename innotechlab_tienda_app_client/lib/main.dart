import 'package:flutter/material.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/config/constants/app_constants.dart';
import 'package:flutter_app/config/router/app_router.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Importa geolocator
import 'package:flutter_app/core/security/secure_local_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> _requestLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Verifica si los servicios de ubicación están habilitados.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Los servicios de ubicación no están habilitados.
    // Considera mostrar un mensaje al usuario o abrir la configuración.
    return;
  }

  // Comprueba el estado actual de los permisos de ubicación.
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // Los permisos están denegados, solicita al usuario.
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Los permisos siguen denegados después de la solicitud.
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Los permisos están denegados permanentemente, no se puede solicitar de nuevo.
    // Debes dirigir al usuario a la configuración de la aplicación.
    return;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env.development");

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );

  runApp(ProviderScope(child: MyApp()));

  // Avoid blocking startup with permission dialogs.
  _requestLocationPermission();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa el proveedor del router para obtener la configuración
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Innotech Tienda',
      theme: AppTheme.light,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
