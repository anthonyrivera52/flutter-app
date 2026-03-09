// lib/main.dart

import 'package:delivery_app_mvvm/data/datasources/earning_remote_datasource.dart';
import 'package:delivery_app_mvvm/data/datasources/home_local_data_source.dart';
import 'package:delivery_app_mvvm/data/datasources/home_remote_data_source.dart';
import 'package:delivery_app_mvvm/data/repositories/earning_repository_impl.dart';
import 'package:delivery_app_mvvm/data/repositories/home_repository_impl.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_daily_earnings.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_earnings_usecase.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_user_online_status.dart';
import 'package:delivery_app_mvvm/domain/usecases/go_offline.dart';
import 'package:delivery_app_mvvm/service/connectivity_service.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:delivery_app_mvvm/service/real_location_service.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart';
import 'package:delivery_app_mvvm/viewmodel/earning_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:delivery_app_mvvm/view/home_screen.dart';

// Importaciones de autenticación
import 'package:delivery_app_mvvm/data/datasources/auth_remote_data_source.dart';
import 'package:delivery_app_mvvm/data/repositories/auth_repository_impl.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_in_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_up_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_out_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_auth_session.dart';

// Importar constantes
import 'package:delivery_app_mvvm/core/utils/constants.dart';

final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Variables de entorno cargadas correctamente');
  } catch (e) {
    debugPrint('Error al cargar variables de entorno: $e');
  }

  // Inicializar constantes desde .env
  _initializeConstants();

  await notificationService.init();

  // Inicializar Supabase con variables de entorno
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  debugPrint('Supabase inicializado: ${AppConstants.supabaseUrl}');
  debugPrint('Método OTP: ${AppConstants.otpMethod}');
  debugPrint(
    'Entorno: ${AppConstants.isDevelopment ? "DESARROLLO" : "PRODUCCIÓN"}',
  );

  runApp(const MyApp());
}

void _initializeConstants() {
  // Cargar valores desde .env con valores por defecto
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final supabaseBucket = dotenv.env['SUPABASE_BUCKET'] ?? 'my_bucket';
  final otpMethod = dotenv.env['OTP_METHOD'] ?? 'supabase';
  final ordersTable = dotenv.env['ORDERS_TABLE'] ?? 'orders';

  // Twilio (opcionales)
  final twilioAccountSid = dotenv.env['TWILIO_ACCOUNT_SID'];
  final twilioAuthToken = dotenv.env['TWILIO_AUTH_TOKEN'];
  final twilioPhoneNumber = dotenv.env['TWILIO_PHONE_NUMBER'];

  AppConstants.initialize(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
    supabaseBucket: supabaseBucket,
    otpMethod: otpMethod,
    twilioAccountSid: twilioAccountSid,
    twilioAuthToken: twilioAuthToken,
    twilioPhoneNumber: twilioPhoneNumber,
    ordersTable: ordersTable,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. SupabaseClient
        Provider<SupabaseClient>(create: (_) => Supabase.instance.client),

        // --- AUTH PROVIDERS ---
        Provider<AuthRemoteDataSource>(
          create: (context) => AuthRemoteDataSourceImpl(
            supabaseClient: context.read<SupabaseClient>(),
          ),
        ),
        Provider<AuthRepositoryImpl>(
          create: (context) => AuthRepositoryImpl(
            remoteDataSource: context.read<AuthRemoteDataSource>(),
          ),
        ),
        Provider<SignInUser>(
          create: (context) => SignInUser(context.read<AuthRepositoryImpl>()),
        ),
        Provider<SignUpUser>(
          create: (context) => SignUpUser(context.read<AuthRepositoryImpl>()),
        ),
        Provider<SignOutUser>(
          create: (context) => SignOutUser(context.read<AuthRepositoryImpl>()),
        ),
        Provider<GetAuthSession>(
          create: (context) =>
              GetAuthSession(context.read<AuthRepositoryImpl>()),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            signInUser: context.read<SignInUser>(),
            signUpUser: context.read<SignUpUser>(),
            signOutUser: context.read<SignOutUser>(),
            getAuthSession: context.read<GetAuthSession>(),
          )..initializeAuthListener(),
        ),

        // --- HOME PROVIDERS ---
        Provider<HomeLocalDataSource>(create: (_) => HomeLocalDataSourceImpl()),
        Provider<HomeRemoteDataSource>(
          create: (_) => HomeRemoteDataSourceImpl(),
        ),
        Provider<HomeRepositoryImpl>(
          create: (context) => HomeRepositoryImpl(
            remoteDataSource: context.read<HomeRemoteDataSource>(),
            localDataSource: context.read<HomeLocalDataSource>(),
          ),
        ),
        Provider<GetUserOnlineStatus>(
          create: (context) =>
              GetUserOnlineStatus(context.read<HomeRepositoryImpl>()),
        ),
        Provider<GoOnline>(
          create: (context) => GoOnline(context.read<HomeRepositoryImpl>()),
        ),
        Provider<GoOffline>(
          create: (context) => GoOffline(context.read<HomeRepositoryImpl>()),
        ),

        // --- SERVICES ---
        Provider<LocationService>(
          create: (_) => RealLocationService(),
          dispose: (context, service) {
            if (service is RealLocationService) {
              service.dispose();
            }
          },
        ),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),

        // --- HOME VIEWMODEL ---
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            context.read<SupabaseClient>(),
            getUserOnlineStatus: context.read<GetUserOnlineStatus>(),
            goOnline: context.read<GoOnline>(),
            goOffline: context.read<GoOffline>(),
            authViewModel: context.read<AuthViewModel>(),
            locationService: context.read<LocationService>(),
            connectivityService: context.read<ConnectivityService>(),
          ),
        ),

        // --- ORDER VIEWMODELS ---
        ChangeNotifierProvider<NewOrderViewModel>(
          create: (context) => NewOrderViewModel(
            Supabase.instance.client,
            notificationService,
            maxRadiusKm: AppConstants.maxRadius,
            locationService: context.read<LocationService>(),
          ),
          lazy: false,
        ),
        ChangeNotifierProvider<ActiveOrderViewModel>(
          create: (context) => ActiveOrderViewModel(
            Supabase.instance.client,
            context,
            locationService: context.read<LocationService>(),
          ),
        ),

        // --- EARNING & WALLET ---
        Provider<EarningRemoteDataSource>(
          create: (context) => EarningRemoteDataSourceImpl(
            supabaseClient: context.read<SupabaseClient>(),
          ),
        ),
        Provider<EarningRepositoryImpl>(
          create: (context) => EarningRepositoryImpl(
            earningRemoteDataSource: context.read<EarningRemoteDataSource>(),
          ),
        ),
        Provider<GetEarnings>(
          create: (context) =>
              GetEarnings(context.read<EarningRepositoryImpl>()),
        ),
        Provider<GetDailyEarnings>(
          create: (context) =>
              GetDailyEarnings(context.read<EarningRepositoryImpl>()),
        ),
        ChangeNotifierProvider(create: (_) => EarningViewModel()),
        ChangeNotifierProvider(create: (_) => WalletViewModel()),
      ],
      child: MaterialApp(
        locale: const Locale('es', 'ES'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('es', '')],
        title: 'Delivery App - ${AppConstants.isDevelopment ? "Dev" : "Prod"}',
        debugShowCheckedModeBanner: AppConstants.isDevelopment,
        theme: _buildAdaptiveTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  // Tema adaptativo para la aplicación
  ThemeData _buildAdaptiveTheme() {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.isDevelopment ? Colors.orange : Colors.blue,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      // Estilos adaptativos
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: AppConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
