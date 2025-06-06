import 'package:flutter/material.dart';
import 'package:flutter_app/config/constants/app_constats.dart';
import 'package:flutter_app/config/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      ),
      routerConfig: appRouter, // Asigna la configuración del router aquí
    );
  }
}
