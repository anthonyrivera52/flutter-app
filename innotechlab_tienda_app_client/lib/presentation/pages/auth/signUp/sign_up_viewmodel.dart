import 'package:flutter/material.dart'; // Necesario para TextEditingController
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/model/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/config/constants/app_constants.dart';

/// Helper to get the appropriate OTP type based on environment configuration.
/// - 'supabase': Uses email OTP (OtpType.signup) for dev/QA
/// - 'twilio': Uses phone SMS OTP (OtpType.sms) for production
OtpType _getOtpType() {
  return AppConstants.otpMethod == 'twilio' ? OtpType.sms : OtpType.signup;
}

/// Helper to get the appropriate email/phone destination based on environment.
/// For Supabase: uses email
/// For Twilio: expects phone number in format +1234567890
String _getOtpDestination(String emailOrPhone) {
  return emailOrPhone;
}

/// Proveedor para el AuthViewModel.
/// Se encarga de crear una instancia del ViewModel y de inyectar sus dependencias.
final authViewModelProvider =
    StateNotifierProvider.autoDispose<AuthViewModel, AuthStateModel>(
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
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// Realiza el proceso de inicio de sesión.
  Future<void> login() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isAuthenticated: false,
    );

    try {
      // Validaciones de entrada (estas son validaciones de "última milla" o de negocio)
      // Las validaciones de formato y obligatoriedad principales deben estar en el validador del TextField.
      if (emailController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty) {
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

      // Supabase Auth call
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          isAuthenticated: true,
          loggedInEmail: response.user?.email ?? emailController.text.trim(),
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
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isAuthenticated: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: ${e.toString()}',
        isAuthenticated: false,
      );
    }
  }

  /// Realiza el proceso de registro.
  /// Envía código OTP según el método configurado (supabase=email, twilio=SMS)
  /// Retorna:
  /// - true: cuando se envió el código OTP exitosamente (requiere verificación)
  /// - false: cuando hay error
  Future<bool> signUp() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isAuthenticated: false,
    );

    try {
      if (emailController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty ||
          confirmPasswordController.text.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Por favor, completa todos los campos.',
          isAuthenticated: false,
        );
        return false;
      }

      if (passwordController.text != confirmPasswordController.text) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Las contraseñas no coinciden.',
          isAuthenticated: false,
        );
        return false;
      }

      final email = emailController.text.trim();

      // Determinar el tipo de OTP según el método configurado
      final otpType = AppConstants.otpMethod == 'twilio'
          ? OtpType.sms
          : OtpType.signup;

      // Crear usuario y enviar código de verificación
      // Usamos signUp que crea el usuario en Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: passwordController.text.trim(),
        data: {'display_name': displayNameController.text.trim()},
        emailRedirectTo: null, // No redirigir a URL, usaremos verificación manual
      );

      if (response.user != null) {
        // El usuario fue creado. Puede o no requerir verificación adicional.
        // Si emailAutoConfirm está habilitado en Supabase, el usuario ya está confirmado.
        // Si no, necesitamos que verifique el código.

        // Guardamos el email para la página de verificación
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          isAuthenticated: response.session != null, // True si se autenticó directamente
          loggedInEmail: email,
        );

        // Si tiene sesión directa, el registro está completo
        if (response.session != null) {
          clearControllers();
          return true;
        }

        // Si no tiene sesión, el usuario necesita verificar el código
        // El email ya fue guardado en state.loggedInEmail
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo completar el registro.',
          isAuthenticated: false,
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isAuthenticated: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Ocurrió un error inesperado al registrarse: ${e.toString()}',
        isAuthenticated: false,
      );
      return false;
    }
  }

  /// Verifica el código OTP para el registro.
  /// Usa Supabase email OTP para dev/QA
  /// Usa Twilio SMS OTP para producción
  Future<bool> verifyOtp(String email, String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // SECURITY: Remove hardcoded OTP bypass in production
    // This should NEVER be in production code
    // Only for local development with explicit flag
    const bool isDevelopment = bool.fromEnvironment('OTP_DEV_MODE', defaultValue: false);
    if (isDevelopment && token == '123456') {
      await Future.delayed(const Duration(milliseconds: 800));
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        loggedInEmail: email,
      );
      return true;
    }

    // Validate OTP format before sending to API
    if (token.length != 6 || !RegExp(r'^\d+$').hasMatch(token)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'El código debe tener 6 dígitos numéricos.',
      );
      return false;
    }

    try {
      // Determinar el tipo de OTP según el método configurado
      final otpType = AppConstants.otpMethod == 'twilio'
          ? OtpType.sms
          : OtpType.signup;

      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: otpType,
      );

      if (response.session != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          loggedInEmail: email,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Verificación fallida. El código puede ser incorrecto o haber expirado.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reenvía el código OTP.
  /// Usa Supabase email OTP para dev/QA
  /// Usa Twilio SMS OTP para producción
  Future<void> resendOtp(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Determinar el tipo de OTP según el método configurado
      final otpType = AppConstants.otpMethod == 'twilio'
          ? OtpType.sms
          : OtpType.signup;

      await Supabase.instance.client.auth.resend(
        type: otpType,
        email: email,
      );
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Alterna la visibilidad de la contraseña (para login y signup).
  // Nota: Si quieres controlar _obscurePassword y _obscureConfirmPassword por separado
  // en el ViewModel, necesitarías dos propiedades distintas en AuthStateModel
  // y dos métodos toggle. Por ahora, se mantienen locales en la UI para SignUpPage.
  // Si se decide moverlos al ViewModel, se usaría la propiedad isPasswordObscured.
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordObscured: !state.isPasswordObscured);
  }

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

  // ignore: unused_element
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
