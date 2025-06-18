import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Para gestionar el estado

// Importa tus ViewModels aquí
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';

// Importa tus vistas
import 'package:delivery_app_mvvm/view/home_screen.dart';
import 'package:delivery_app_mvvm/view/new_order_notification_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Instancia global del servicio de notificaciones
final NotificationService notificationService = NotificationService();

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized(); // Asegura que Flutter esté inicializado

  // Inicializa Supabase
  await Supabase.initialize(
    url: 'https://ofzswnqjqgjiwsbvybou.supabase.co', // <-- ¡REEMPLAZA CON TU URL REAL DE SUPABASE!
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9menN3bnFqcWdqaXdzYnZ5Ym91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMzUwMjcsImV4cCI6MjA2MzcxMTAyN30.orFqPDhX3xMKT2jra7ZVKNUcwwpOO3_mGQf9hKBZprE'
  );

  // Inicializa el servicio de notificaciones
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewOrderViewModel()),
        ChangeNotifierProvider(create: (_) => ActiveOrderViewModel()),
        // Puedes añadir más ViewModels aquí
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    // Escucha las respuestas de las notificaciones para navegar
    notificationService.onNotifications.listen((payload) {
      if (payload != null && navigatorKey.currentState != null) {
        // Navega a la ruta especificada en el payload (que será el ID de la orden)
        // Usamos pushNamedAndRemoveUntil para limpiar el stack de navegación
        // y asegurar que la pantalla de detalles sea la principal después de la notificación.
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/order_details',
          (route) => route.isFirst, // Vuelve a la primera ruta del stack
          arguments: payload, // Pasa el ID de la orden como argumento
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery App MVVM',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HomeScreen(), // La pantalla inicial de tu app
      routes: {
        '/new_order': (context) => NewOrderNotificationScreen(),
      },
    );
  }
}