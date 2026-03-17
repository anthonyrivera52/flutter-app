import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Innotech Tienda';
  static const String appVersion = '0.0.1';
  static const int defaultTimeout = 30;

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'URL no encontrada';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'KEY no encontrada';
  static String get supabaseBucket =>
      dotenv.env['SUPABASE_BUCKET'] ?? 'BUCKET no encontrado';
  static String get otpMethod => dotenv.env['OTP_METHOD'] ?? 'supabase';

  static String get supabaseStorageUrl =>
      '$supabaseUrl/storage/v1/object/public/$supabaseBucket/';
}
