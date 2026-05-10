import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordObscured;
  final bool isAuthenticated;
  final bool otpSent;
  final OtpType? otpType;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordObscured = true,
    this.isAuthenticated = false,
    this.otpSent = false,
    this.otpType,
  });
}