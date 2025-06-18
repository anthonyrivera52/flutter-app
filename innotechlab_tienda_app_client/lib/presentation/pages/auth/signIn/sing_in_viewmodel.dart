import 'package:flutter/cupertino.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/model/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authViewModel = StateNotifierProvider<AuthViewModel, AuthStateModel>(
  (ref) => AuthViewModel(),
);

class AuthViewModel extends StateNotifier<AuthStateModel> {
  AuthViewModel() : super(AuthStateModel());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
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

      if (true) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          isAuthenticated: true,
          loggedInEmail: emailController.text.trim(),
        );
        emailController.clear();
        passwordController.clear();
      }

      // final result = await AuthModel.login(
      //   email: emailController.text.trim(),
      //   password: passwordController.text.trim(),
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
      //       errorMessage: null,
      //       isAuthenticated: true,
      //     );
      //     // Opcional: limpiar los controladores después de un inicio de sesión exitoso
      //     emailController.clear();
      //     passwordController.clear();
          // if (true) {
          //   context.go('/otp-verification', extra: emailController.text.trim());
          // }
      //   },
      // );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: ${e.toString()}',
        isAuthenticated: false,
      );
    } finally {
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        isAuthenticated: true,
      );
    }
  }

    /// Alterna la visibilidad de la contraseña.
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordObscured: !state.isPasswordObscured);
  }

  /// Limpia el mensaje de error actual.
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  /// Limpia los controladores de texto.
  void clearControllers() {
    emailController.clear();
    passwordController.clear();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  @override
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
