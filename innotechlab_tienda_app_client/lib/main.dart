import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/config/router/app_router.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/service_locator.dart'; // Asegúrate de que este archivo define los providers
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mi_tienda/core/network/network_info_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INICIALIZACIÓN DE DEPENDENCIAS ---
  // 1. Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // 2. Inicializar Supabase
  // !!! IMPORTANTE: REEMPLAZA CON TUS PROPIAS URL Y ANON KEY DE SUPABASE !!!
  await Supabase.initialize(
    url: 'https://ofzswnqjqgjiwsbvybou.supabase.co', // Reemplaza con tu URL de Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9menN3bnFqcWdqaXdzYnZ5Ym91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMzUwMjcsImV4cCI6MjA2MzcxMTAyN30.orFqPDhX3xMKT2jra7ZVKNUcwwpOO3_mGQf9hKBZprE', // Reemplaza con tu Anon Key de Supabase
  );
  // --- FIN INICIALIZACIÓN DE DEPENDENCIAS ---

  // 3. Configurar los Providers de Riverpod con los overrides iniciales
  // Se pasa la lista de overrides directamente al constructor del ProviderContainer
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      // CORREGIDO: Override connectivityInstanceProvider directly here
      connectivityInstanceProvider.overrideWithValue(Connectivity()),
      // networkInfoProvider will now correctly read the overridden connectivityInstanceProvider
      // from the container's scope, so no explicit override for networkInfoProvider is needed here.
    ],
  );

  // La función setupRiverpodProviders ya no es necesaria para overrides.
  // Si setupRiverpodProviders contenía lógica de inicialización temprana (como pre-leer providers),
  // esa lógica debería ser movida aquí o a un lugar donde se ejecute después de la creación del contenedor.
  // En este caso, la llamada a setupRiverpodProviders se ha eliminado.

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);

    return MyAppWithConnectivityListener( // Envuelve la app con el listener de conectividad
      child: MaterialApp.router(
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        title: 'Mi Tienda',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor,
            primary: AppColors.primaryColor,
            onPrimary: AppColors.cardColor,
            secondary: AppColors.secondaryColor,
            onSecondary: AppColors.textColor,
            surface: AppColors.cardColor,
            onSurface: AppColors.textColor,
            background: AppColors.backgroundColor,
            onBackground: AppColors.textColor,
            error: AppColors.errorColor,
            onError: AppColors.cardColor,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.cardColor,
            centerTitle: true,
            elevation: 0,
          ),
          scaffoldBackgroundColor: AppColors.backgroundColor,
          cardTheme: CardThemeData(
            color: AppColors.cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.greyMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
            ),
            labelStyle: const TextStyle(color: AppColors.textLightColor),
            hintStyle: const TextStyle(color: AppColors.greyMedium),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: AppColors.textColor),
            displayMedium: TextStyle(color: AppColors.textColor),
            displaySmall: TextStyle(color: AppColors.textColor),
            headlineLarge: TextStyle(color: AppColors.textColor),
            headlineMedium: TextStyle(color: AppColors.textColor),
            headlineSmall: TextStyle(color: AppColors.textColor),
            titleLarge: TextStyle(color: AppColors.textColor),
            titleMedium: TextStyle(color: AppColors.textColor),
            titleSmall: TextStyle(color: AppColors.textColor),
            bodyLarge: TextStyle(color: AppColors.textColor),
            bodyMedium: TextStyle(color: AppColors.textColor),
            bodySmall: TextStyle(color: AppColors.textLightColor),
            labelLarge: TextStyle(color: AppColors.textColor),
            labelMedium: TextStyle(color: AppColors.textColor),
            labelSmall: TextStyle(color: AppColors.textColor),
          ),
        ),
      ),
    );
  }
}

// Clase para envolver el MaterialApp y escuchar cambios de conectividad
class MyAppWithConnectivityListener extends ConsumerStatefulWidget {
  final Widget child;

  const MyAppWithConnectivityListener({super.key, required this.child});

  @override
  ConsumerState<MyAppWithConnectivityListener> createState() => _MyAppWithConnectivityListenerState();
}

class _MyAppWithConnectivityListenerState extends ConsumerState<MyAppWithConnectivityListener> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  SnackBar? _noInternetSnackBar;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en la conectividad al inicializar el widget
    ref.read(networkInfoProvider).onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.every((result) => result == ConnectivityResult.none)) {
        _showNoInternetSnackBar();
      } else {
        _hideNoInternetSnackBar();
      }
    });
  }

  void _showNoInternetSnackBar() {
    if (_noInternetSnackBar != null) return;

    _noInternetSnackBar = SnackBar(
      content: Row(
        children: const [
          Icon(Icons.wifi_off, color: Colors.white),
          SizedBox(width: 10),
          Expanded(child: Text('Sin conexión a internet. Algunas funciones pueden no estar disponibles.', style: TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(days: 365), // Muestra la SnackBar indefinidamente
      behavior: SnackBarBehavior.fixed,
    );
    _scaffoldMessengerKey.currentState?.showSnackBar(_noInternetSnackBar!);
  }

  void _hideNoInternetSnackBar() {
    if (_noInternetSnackBar != null) {
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _noInternetSnackBar = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: widget.child,
    );
  }
}
