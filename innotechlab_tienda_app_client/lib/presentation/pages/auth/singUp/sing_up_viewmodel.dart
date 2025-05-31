import 'package:flutter/material.dart'; // Necesario para TextEditingController
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/model/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor para el AuthViewModel.
/// Se encarga de crear una instancia del ViewModel y de inyectar sus dependencias.
final authViewModelProvider = StateNotifierProvider.autoDispose<AuthViewModel, AuthStateModel>(
  (ref) => AuthViewModel(),
);

/// ViewModel para la gestión de autenticación (SignIn, SignUp, SignOut).
/// Centraliza la lógica de negocio relacionada con la autenticación.
class AuthViewModel extends StateNotifier<AuthStateModel> {
  AuthViewModel() : super(AuthStateModel());
  // Controladores de texto gestionados por el ViewModel
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  /// Realiza el proceso de inicio de sesión.
  Future<void> login() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isAuthenticated: false);

    try {
      // Validaciones de entrada (estas son validaciones de "última milla" o de negocio)
      // Las validaciones de formato y obligatoriedad principales deben estar en el validador del TextField.
      if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Por favor, completa todos los campos.',
          isAuthenticated: false,
        );
        return;
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(emailController.text.trim())) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Introduce un correo electrónico válido.',
          isAuthenticated: false,
        );
        return;
      }

      // Simulación de un error o éxito para login
      await Future.delayed(const Duration(seconds: 1)); // Simula una llamada a la API
      if (true) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          isAuthenticated: true,
          loggedInEmail: emailController.text.trim(), // Guarda el email logueado
        );
        emailController.clear();
        passwordController.clear();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Credenciales incorrectas. Inténtalo de nuevo.',
          isAuthenticated: false,
        );
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: ${e.toString()}',
        isAuthenticated: false,
      );
    }
  }

  /// Realiza el proceso de registro.
  Future<void> signUp() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isAuthenticated: false);

    try {
      // Las validaciones de campos vacíos, formato de email, longitud de contraseña
      // y coincidencia de contraseñas ya se manejan en los validators de los CustomTextFields.
      // Aquí, el ViewModel se enfoca en la lógica de negocio después de que la UI valida.

      // Simulación de un error o éxito para signUp
      // En un caso real, aquí llamarías a tu caso de uso de sign-up
      // final result = await _signUpUseCase(
      //   SignUpParams(
      //     email: emailController.text.trim(),
      //     password: passwordController.text.trim(),
      //     displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
      //   ),
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
      //       loggedInEmail: emailController.text.trim(), // Guarda el email registrado
      //     );
      //     clearControllers(); // Limpia todos los controladores al registrarse
      //   },
      // );

      // *** Lógica de simulación actual para signUp (reemplazar con el caso de uso real) ***
      await Future.delayed(const Duration(seconds: 1)); // Simula una llamada a la API

      // Simular un registro exitoso si las validaciones de UI pasaron
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        isAuthenticated: true,
        loggedInEmail: emailController.text.trim(), // Guarda el email registrado
      );
      clearControllers(); // Limpia todos los controladores al registrarse
      // **********************************************************************

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrió un error inesperado al registrarse: ${e.toString()}',
        isAuthenticated: false,
      );
    }
  }
  
  /// Alterna la visibilidad de la contraseña (para login y signup).
  // Nota: Si quieres controlar _obscurePassword y _obscureConfirmPassword por separado
  // en el ViewModel, necesitarías dos propiedades distintas en AuthStateModel
  // y dos métodos toggle. Por ahora, se mantienen locales en la UI para SignUpPage.
  // Si se decide moverlos al ViewModel, se usaría la propiedad isPasswordObscured.
  // void togglePasswordVisibility() {
  //   state = state.copyWith(isPasswordObscured: !state.isPasswordObscured);
  // }

  /// Limpia el mensaje de error actual.
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  /// Limpia todos los controladores de texto.
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
