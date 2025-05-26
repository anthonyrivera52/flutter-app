import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/constants/app_constants.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:mi_tienda/service_locator.dart';
// Removed duplicate: import 'package:mi_tienda/core/utils/app_colors.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
// Removed duplicate: import 'package:mi_tienda/service_locator.dart'; 
// Note: service_locator.dart was imported twice, one is removed.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INICIALIZACIÓN DE DEPENDENCIAS ---
  // Asegúrate de reemplazar 'TU_URL_SUPABASE' y 'TU_ANON_KEY_SUPABASE'
  await Supabase.initialize(
    url: AppConstants.supabaseUrl, // <-- ¡REEMPLAZA CON TU URL DE SUPABASE!
    anonKey: AppConstants.supabaseAnonKey, // <-- ¡REEMPLAZA CON TU ANON KEY DE SUPABASE!
  );

  // Inicializa tu service locator si lo estás usando
  // setupSharedPreferences() is called by service_locator.dart itself if needed.
  // No need to call it explicitly here if setupLocator handles it.
  // For now, assuming setupSharedPreferences is part of the service locator setup.
  await setupLocator(); // Assuming setupLocator() initializes shared_preferences
  // --- FIN INICIALIZACIÓN DE DEPENDENCIAS ---

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa el proveedor de GoRouter para la navegación.
    final appRouter = ref.watch(appRouterProvider);

    return MyAppWithConnectivityListener(
      child: MaterialApp.router(
        routerConfig: appRouter, // Asigna tu configuración de rutas
        // **NUEVO: Usa MaterialApp.router para la navegación**
        routerDelegate: appRouter.routerDelegate,
        routeInformationParser: appRouter.routeInformationParser,
        debugShowCheckedModeBanner: false, // Oculta la etiqueta de debug
        title: 'Mi Tienda',
        theme: ThemeData(
          // **NUEVO: Usa ColorScheme para definir la paleta de colores de tu app**
          colorScheme: ColorScheme.fromSeed(
            // seedColor es el color base para generar tonos derivados automáticamente
            seedColor: AppColors.primaryColor,

            // Define explícitamente los colores principales de tu paleta
            primary: AppColors.primaryColor, // Color principal de la marca
            onPrimary: AppColors.cardColor, // Color del texto/iconos que van sobre primary

            secondary: AppColors.secondaryColor, // Color de acento
            onSecondary: AppColors.textColor, // Color del texto/iconos que van sobre secondary

            surface: AppColors.cardColor, // Color para tarjetas, dialogs, hojas inferiores
            onSurface: AppColors.textColor, // Color del texto/iconos que van sobre surface

            background: AppColors.backgroundColor, // Color de fondo general de las pantallas
            onBackground: AppColors.textColor, // Color del texto/iconos que van sobre background

            error: AppColors.errorColor, // Color para mensajes de error
            onError: AppColors.cardColor, // Color del texto/iconos que van sobre error

            brightness: Brightness.light, // Puedes cambiar a Brightness.dark para un tema oscuro
          ),

          // **Configuración de componentes específicos para usar tus colores**
          // Tema de la barra de aplicación (AppBar)
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor, // Fondo del AppBar
            foregroundColor: AppColors.cardColor, // Color de los iconos y texto del AppBar
            centerTitle: true,
            elevation: 0, // Sin sombra bajo el AppBar
          ),

          // Color de fondo predeterminado para Scaffolds
          scaffoldBackgroundColor: AppColors.backgroundColor,

          // Tema de las tarjetas (Card)
          cardTheme: CardThemeData(
            color: AppColors.cardColor, // Color de fondo de las tarjetas
            elevation: 4, // Sombra de las tarjetas
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bordes redondeados
            ),
          ),

          // Tema de los campos de entrada (TextField, TextFormField)
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.cardColor, // Fondo de los campos de entrada
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.greyLight), // Borde por defecto
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.greyMedium), // Borde cuando está habilitado
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2), // Borde cuando está enfocado
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorColor), // Borde cuando hay error
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorColor, width: 2), // Borde de error enfocado
            ),
            labelStyle: const TextStyle(color: AppColors.textLightColor), // Estilo del label
            hintStyle: const TextStyle(color: AppColors.greyMedium), // Estilo del hint
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),

          // Tema de los botones elevados (ElevatedButton)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor, // Color de fondo del botón
              foregroundColor: AppColors.cardColor, // Color del texto del botón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Bordes redondeados
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Tema de los botones de texto (TextButton)
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor, // Color del texto del botón de texto
            ),
          ),

          // **Opcional: Define estilos de texto si necesitas algo diferente a los predeterminados**
          textTheme: const TextTheme(
            // Ejemplos, puedes ajustar según tu diseño
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
            bodySmall: TextStyle(color: AppColors.textLightColor), // Texto más sutil
            labelLarge: TextStyle(color: AppColors.textColor),
            labelMedium: TextStyle(color: AppColors.textColor),
            labelSmall: TextStyle(color: AppColors.textColor),
          ),
        ),
      ),
      // The theme property for MyAppWithConnectivityListener is removed as it's redundant.
      // The main theme is defined in MaterialApp.router.
    );
  }
}