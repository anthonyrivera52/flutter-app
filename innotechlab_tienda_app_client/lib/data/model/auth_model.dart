
import 'package:flutter_app/domain/entities/auth.dart';

class AuthStateModel extends AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordObscured;
  final bool isAuthenticated; // Para indicar si la autenticación fue exitosa

  AuthStateModel({
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordObscured = true,
    this.isAuthenticated = false,
  });

  /// Crea una nueva instancia de AuthStateModel con valores actualizados.
  AuthStateModel copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordObscured,
    bool? isAuthenticated, 
  }) {
    return AuthStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Se pasa directamente para permitir null
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}