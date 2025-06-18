import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Para gestionar el estado

// Importa tus ViewModels aquí
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';

// Importa tus vistas
import 'package:delivery_app_mvvm/view/home_screen.dart';
import 'package:delivery_app_mvvm/view/new_order_notification_screen.dart';

void main() {
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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