import 'package:flutter_app/features/auth/domain/models/auth_entity.dart';

class AuthStateModel extends AuthState {
  final String?
  loggedInEmail; // Para almacenar el correo electrónico del usuario autenticado

  AuthStateModel({
    super.isLoading = false,
    super.errorMessage,
    super.isPasswordObscured = true,
    super.isAuthenticated = false,
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
