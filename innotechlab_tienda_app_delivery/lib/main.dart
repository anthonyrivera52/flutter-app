// main.dart
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:delivery_app_mvvm/view/home_screen.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase
  await Supabase.initialize(
    url: 'https://ofzswnqjqgjiwsbvybou.supabase.co', // <-- ¡REEMPLAZA CON TU URL REAL DE SUPABASE!
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9menN3bnFqcWdqaXdzYnZ5Ym91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMzUwMjcsImV4cCI6MjA2MzcxMTAyN30.orFqPDhX3xMKT2jra7ZVKNUcwwpOO3_mGQf9hKBZprE'
  );

  final NotificationService notificationService = NotificationService();
  await notificationService.init(); // Initialize notification service once

  runApp(
    MultiProvider(
      providers: [
        // NewOrderViewModel needs SupabaseClient and NotificationService
        ChangeNotifierProvider(
          create: (context) => NewOrderViewModel(
            Supabase.instance.client,
            notificationService, // Pass the initialized instance
          ),
          lazy: false, // Ensures ViewModel is created immediately and starts listening
        ),
        // ActiveOrderViewModel (if it needs Supabase, pass it here too)
        ChangeNotifierProvider(
          create: (context) => ActiveOrderViewModel(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const HomeScreen(), // Your main screen
      // Add routes if you're using them (e.g., for navigation from notifications)
      // routes: {
      //   '/order_details': (context) => OrderDetailsScreen(),
      // },
      navigatorKey: navigatorKey, // From your notification_service.dart
    );
  }
}