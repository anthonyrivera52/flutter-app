import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateProfile {
  final bool isLoading;
  final User? user; 
  final String? errorMessage;

  AuthStateProfile({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });
}