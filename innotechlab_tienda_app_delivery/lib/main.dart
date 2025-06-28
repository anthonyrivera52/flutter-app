// lib/main.dart
import 'package:delivery_app_mvvm/service/connectivity_service.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:delivery_app_mvvm/service/real_location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tus importaciones existentes (asegúrate de que las rutas sean correctas)
import 'package:delivery_app_mvvm/data/datasources/home_local_data_source.dart';
import 'package:delivery_app_mvvm/data/datasources/home_remote_data_source.dart';
import 'package:delivery_app_mvvm/data/repositories/home_repository_impl.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_user_online_status.dart';
import 'package:delivery_app_mvvm/domain/usecases/go_offline.dart';
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/view/home_screen.dart';

// Importaciones de autenticación
import 'package:delivery_app_mvvm/data/datasources/auth_remote_data_source.dart';
import 'package:delivery_app_mvvm/data/repositories/auth_repository_impl.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_in_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_up_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_out_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_auth_session.dart';
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart';


final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await notificationService.init(); // Initialize notification service once

  await Supabase.initialize(
    url: 'https://ofzswnqjqgjiwsbvybou.supabase.co', // <-- ¡REEMPLAZA CON TU URL REAL DE SUPABASE!
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9menN3bnFqcWdqaXdzYnZ5Ym91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMzUwMjcsImV4cCI6MjA2MzcxMTAyN30.orFqPDhX3xMKT2jra7ZVKNUcwwpOO3_mGQf9hKBZprE'
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. SupabaseClient - La base, no depende de nada más
        Provider<SupabaseClient>(
          create: (_) {
            return Supabase.instance.client;
          },
        ),

        // --- PROVEEDORES RELACIONADOS CON LA AUTENTICACIÓN ---
        // 2. AuthRemoteDataSource - Depende de SupabaseClient
        Provider<AuthRemoteDataSource>(
          create: (context) {
            return AuthRemoteDataSourceImpl(
              supabaseClient: context.read<SupabaseClient>(),
            );
          },
        ),
        // 3. AuthRepositoryImpl - Depende de AuthRemoteDataSource
        Provider<AuthRepositoryImpl>(
          create: (context) {
            return AuthRepositoryImpl(
              remoteDataSource: context.read<AuthRemoteDataSource>(),
            );
          },
        ),
        // 4. Casos de Uso de Autenticación - Dependen de AuthRepositoryImpl
        Provider<SignInUser>(
          create: (context) {
            return SignInUser(context.read<AuthRepositoryImpl>());
          },
        ),
        Provider<SignUpUser>(
          create: (context) {
            return SignUpUser(context.read<AuthRepositoryImpl>());
          },
        ),
        Provider<SignOutUser>(
          create: (context) {
            return SignOutUser(context.read<AuthRepositoryImpl>());
          },
        ),
        Provider<GetAuthSession>(
          create: (context) {
            return GetAuthSession(context.read<AuthRepositoryImpl>());
          },
        ),
        // 5. AuthViewModel - Depende de los casos de uso de autenticación
        // ¡Este es el Provider que HomeScreen necesita!
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) {
            return AuthViewModel(
              signInUser: context.read<SignInUser>(),
              signUpUser: context.read<SignUpUser>(),
              signOutUser: context.read<SignOutUser>(),
              getAuthSession: context.read<GetAuthSession>(),
            )..initializeAuthListener();
          },
        ),

        // --- PROVEEDORES DE LA FUNCIONALIDAD PRINCIPAL (HOME) ---
        // 6. HomeLocalDataSource, HomeRemoteDataSource - No tienen dependencias directas en otros providers
        Provider<HomeLocalDataSource>(
          create: (_) {
            return HomeLocalDataSourceImpl();
          },
        ),
        Provider<HomeRemoteDataSource>(
          create: (_) {
            return HomeRemoteDataSourceImpl();
          },
        ),
        // 7. HomeRepositoryImpl - Depende de HomeLocalDataSource y HomeRemoteDataSource
        Provider<HomeRepositoryImpl>(
          create: (context) {
            return HomeRepositoryImpl(
              remoteDataSource: context.read<HomeRemoteDataSource>(),
              localDataSource: context.read<HomeLocalDataSource>(),
            );
          },
        ),
        // 8. Casos de Uso de Home - Dependen de HomeRepositoryImpl
        Provider<GetUserOnlineStatus>(
          create: (context) {
            return GetUserOnlineStatus(context.read<HomeRepositoryImpl>());
          },
        ),
        Provider<GoOnline>(
          create: (context) {
            return GoOnline(context.read<HomeRepositoryImpl>());
          },
        ),
        Provider<GoOffline>(
          create: (context) {
            return GoOffline(context.read<HomeRepositoryImpl>());
          },
        ),


        // =============================================================
        // AÑADE AQUI LOS NUEVOS PROVIDERS PARA SERVICIOS
        // =============================================================
        Provider<LocationService>(
          create: (_) => RealLocationService(), // Provee la implementación real
          dispose: (context, service) {
            if (service is RealLocationService) {
              service.dispose(); // Asegúrate de llamar a dispose
            }
          },
        ),
        Provider<ConnectivityService>(
          create: (_) => ConnectivityService(), // Provee tu servicio de conectividad
        ),
        // =============================================================

        // 9. HomeViewModel - Depende de los casos de uso de Home Y AuthViewModel
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) {
            return HomeViewModel(
              context.read<SupabaseClient>(),
              getUserOnlineStatus: context.read<GetUserOnlineStatus>(),
              goOnline: context.read<GoOnline>(),
              goOffline: context.read<GoOffline>(),
              authViewModel: context.read<AuthViewModel>(),
              
              // =============================================================
              // INYECTA LOS NUEVOS SERVICIOS EN EL CONSTRUCTOR DE HomeViewModel
              // =============================================================
              locationService: context.read<LocationService>(),
              connectivityService: context.read<ConnectivityService>(),
              // ============================================================= // <-- Aquí lee AuthViewModel
            );
          },
        ),

        // Otros ViewModels que uses (asegúrate de que sus dependencias se resuelvan antes si las tienen)
        ChangeNotifierProvider<NewOrderViewModel>(
          create: (context) => NewOrderViewModel(
            Supabase.instance.client,
            notificationService, // Pass the initialized instance
          ),
          lazy: false, // Ensures ViewModel is created immediately and starts listening
        ),
        ChangeNotifierProvider<ActiveOrderViewModel>(
          create: (context) {
            return ActiveOrderViewModel(Supabase.instance.client, context, 
              locationService: context.read<LocationService>(),);
          },
        ),
      ],
      // MaterialApp es el hijo de MultiProvider, por lo tanto, HomeScreen (que es home)
      // tendrá acceso a todos los providers declarados arriba.
      child: MaterialApp(
        title: 'Delivery App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(), // Esta línea es la que da el error (main.dart:135:19)
      ),
    );
  }
}