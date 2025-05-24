
import 'package:flutter/material.dart';
import 'package:flutter_app/core/routes/router.dart';
import 'package:flutter_app/core/services/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init(); // Inicializar GetIt
  // await SupabaseService.init(Flavor.CLIENT); // Inicializar Supabase
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'App Client',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
