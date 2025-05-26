
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Riverpod Example'),
        ),
        body: Center(
          child: Text('Hello, Riverpod!'),
        ),
      ),
      // Aquí puedes definir las rutas de tu aplicación
      // routes: {
      //   '/login': (context) => LoginPage(),
      //   '/dashboard': (context) => DashboardPage(),
      // },
    );
  }
}
