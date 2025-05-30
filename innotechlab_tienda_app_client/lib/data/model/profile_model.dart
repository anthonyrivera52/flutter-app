import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Asumiendo que User es de supabase_flutter

/// Representa el estado del perfil de autenticación.
/// Es inmutable y se usa con el AuthNotifierProfile.
class AuthStateProfileModel extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final User? user; // El usuario actualmente autenticado
  final bool isAuthenticated; // Indica si hay un usuario autenticado

  const AuthStateProfileModel({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.isAuthenticated = false, // Por defecto, no autenticado
  });

  /// Crea una nueva instancia de AuthStateProfileModel con valores actualizados.
  AuthStateProfileModel copyWith({
    bool? isLoading,
    String? errorMessage,
    User? user,
    bool? isAuthenticated,
  }) {
    return AuthStateProfileModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Se pasa directamente para permitir null
      user: user, // Se pasa directamente para permitir null (ej. al cerrar sesión)
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, user, isAuthenticated];
}
