import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_app/features/auth/domain/models/auth_entity.dart';

class AuthStateModel extends AuthState {
  final String? loggedInEmail;

  AuthStateModel({
    super.isLoading = false,
    super.errorMessage,
    super.isPasswordObscured = true,
    super.isAuthenticated = false,
    super.otpType,
    this.loggedInEmail = "",
  });

  AuthStateModel copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordObscured,
    bool? isAuthenticated,
    String? loggedInEmail,
    OtpType? otpType,
  }) {
    return AuthStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      loggedInEmail: loggedInEmail ?? this.loggedInEmail,
      otpType: otpType ?? this.otpType,
    );
  }
}
