import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/model/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';// Para NoParams

/// Proveedor para AuthNotifierProfile.
/// Inyecta las dependencias necesarias (casos de uso).
final authProfileProvider = StateNotifierProvider<AuthNotifierProfile, AuthStateProfileModel>(
  (ref) => AuthNotifierProfile(),
);

/// ViewModel para la gestión del perfil de usuario y el cierre de sesión.
class AuthNotifierProfile extends StateNotifier<AuthStateProfileModel> {
  AuthNotifierProfile() : super(const AuthStateProfileModel());

  /// Actualiza el perfil del usuario.
  Future<void> updateUserProfile({String? username, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // final result = await _updateUserProfileUseCase(
    //   UpdateUserProfileParams(username: username, avatarUrl: avatarUrl),
    // );
    // result.fold(
    //   (failure) {
    //     state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
    //   },
    //   (updatedUser) {
    //     state = state.copyWith(isLoading: false, user: updatedUser);
    //   },
    // );
    return Future.delayed(
      const Duration(seconds: 2),
      () {
        state = state.copyWith(
          isLoading: false,
          user: null, // Simulación de actualización
        );
      },
    );
  }

  /// Sube una imagen de perfil.
  Future<String?> uploadProfileImage(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // final result = await _uploadProfileImageUseCase(UploadProfileImageParams(filePath: filePath));
    // return result.fold(
    //   (failure) {
    //     state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
    //     return null;
    //   },
    //   (imageUrl) {
    //     state = state.copyWith(isLoading: false);
    //     return imageUrl;
    //   },
    // );
    return Future.delayed(
      const Duration(seconds: 2),
      () {
        state = state.copyWith(
          isLoading: false,
          user: null, // Simulación de subida de imagen
        );
        return 'https://example.com/new-avatar.png'; // URL simulada
      },
    );
  }

  /// Realiza el cierre de sesión del usuario.
  /// Este método ya NO recibe BuildContext.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // final result = await _signOutUseCase(const NoParams()); // Llama al caso de uso de cierre de sesión

    // result.fold(
    //   (failure) {
    //     state = state.copyWith(
    //       isLoading: false,
    //       errorMessage: _mapFailureToMessage(failure),
    //       isAuthenticated: true, // Sigue autenticado si falla el cierre de sesión
    //     );
    //   },
    //   (_) {
    //     state = state.copyWith(
    //       isLoading: false,
    //       user: null, // Limpia el usuario al cerrar sesión
    //       errorMessage: null,
    //       isAuthenticated: false, // Establece como no autenticado
    //     );
    //   },
    // );
    return Future.delayed(
      const Duration(seconds: 2),
      () {
        state = state.copyWith(
          isLoading: false,
          user: null, // Simulación de cierre de sesión
          errorMessage: null,
          isAuthenticated: false, // Establece como no autenticado
        );
      },
    );
  }

  /// Limpia el mensaje de error actual.
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  /// Mapea un objeto Failure a un mensaje de error legible.
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is AuthFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) { // Añadido NetworkFailure si lo tienes
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else {
      return 'Ocurrió un error inesperado.';
    }
  }
}
