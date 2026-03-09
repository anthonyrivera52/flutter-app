import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'My Tienda';
  static const String appVersion = '0.0.1';
  static const String apiBaseUrl = 'https://api.example.com/v1/';
  static const int defaultTimeout = 30; // in seconds
  static const String defaultLanguage = 'en';
  static const String defaultCurrency = 'USD';

  // Add variable supabase
  static String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'URL no encontrada';
  static String supabaseAnonKey =
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'KEY no encontrada';
  static String supabaseBucket =
      dotenv.env['SUPABASE_BUCKET'] ?? 'BUCKET no encontrado';

  // OTP Configuration
  // 'supabase' - uses Supabase email OTP (dev/QA)
  // 'twilio' - uses Twilio SMS OTP (production)
  static String otpMethod = dotenv.env['OTP_METHOD'] ?? 'supabase';

  static String get supabaseStorageUrl =>
      '$supabaseUrl/storage/v1/object/public/$supabaseBucket/';
  static String get supabaseStoragePath => '$supabaseBucket/';
}
