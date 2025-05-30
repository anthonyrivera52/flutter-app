import 'package:flutter/cupertino.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/model/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final authViewModel = StateNotifierProvider<AuthViewModel, AuthStateModel>(
  (ref) => AuthViewModel(),
);

class AuthViewModel extends StateNotifier<AuthStateModel> {
  AuthViewModel() : super(AuthStateModel());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> signUp() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isAuthenticated: false);

    try {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Por favor, completa todos los campos.',
          isAuthenticated: false,
        );
        return;
      }

      // Validación de formato de correo electrónico
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(emailController.text.trim())) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Introduce un correo electrónico válido.',
          isAuthenticated: false,
        );
        return;
      }

      if (passwordController.text.length < 6) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'La contraseña debe tener al menos 6 caracteres.',
          isAuthenticated: false,
        );
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Las contraseñas no coinciden.',
          isAuthenticated: false,
        );
        return;
      }

      if (true) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          isAuthenticated: true,
          loggedInEmail: emailController.text.trim(),
        );
        emailController.clear();
        passwordController.clear();
        displayNameController.clear();
        confirmPasswordController.clear();
      }

      // Aquí se llamaría al método de registro del modelo de autenticación
      // final result = await AuthModel.signUp(
      //   email: emailController.text.trim(),
      //   password: passwordController.text.trim(),
      //   displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
      // );

      // result.fold(
      //   (failure) {
      //     state = state.copyWith(
      //       isLoading: false,
      //       errorMessage: _mapFailureToMessage(failure),
      //       isAuthenticated: false,
      //     );
      //   },
      //   (user) {
      //     state = state.copyWith(
      //       isLoading: false,
      //       user: user,
      //       isAuthenticated: true,
      //     );
      //     context.go('/');
      //   },
      // );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrió un error inesperado. Por favor, inténtalo de nuevo más tarde.',
        isAuthenticated: false,
      );
    }
  }
  
    /// Limpia el mensaje de error actual.
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  void clearControllers() {
    emailController.clear();
    passwordController.clear();
    displayNameController.clear();
    confirmPasswordController.clear();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else if (failure is AuthFailure) {
      return failure.message;
    } else {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}