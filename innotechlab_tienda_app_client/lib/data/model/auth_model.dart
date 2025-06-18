
import 'package:flutter_app/domain/entities/auth.dart';

class AuthStateModel extends AuthState {
  @override
  final bool isLoading;
  @override
  final String? errorMessage;
  @override
  final bool isPasswordObscured;
  @override
  final bool isAuthenticated; // Para indicar si la autenticación fue exitosa
  final String? loggedInEmail; // Para almacenar el correo electrónico del usuario autenticado

  AuthStateModel({
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordObscured = true,
    this.isAuthenticated = false,
    this.loggedInEmail = "",
  });

  /// Crea una nueva instancia de AuthStateModel con valores actualizados.
  AuthStateModel copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordObscured,
    bool? isAuthenticated,
    String? loggedInEmail,
  }) {
    return AuthStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Se pasa directamente para permitir null
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      loggedInEmail: loggedInEmail ?? this.loggedInEmail,
    );
  }
}