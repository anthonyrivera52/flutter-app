
import 'package:flutter_app/modules/auth/data/models/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthStateModel>(
  (ref) => AuthViewModel(),
);

class AuthViewModel extends StateNotifier<AuthStateModel> {
  AuthViewModel() : super(AuthStateModel());

  void setEmail(String value) {
    state = state.copyWith(email: value) as AuthStateModel;
  }

  void setPassword(String value) {
    state = state.copyWith(password: value) as AuthStateModel;
  }

  Future<void> login(context) async {
    state = state.copyWith(loading: true, errorMessage: null) as AuthStateModel;
    try {
      /*final response = await SupabaseService.client.auth.signInWithPassword(
        email: state.email,
        password: state.password,
      );

      if (response.error != null) {
        state = state.copyWith(errorMessage: response.error!.message);
      } else {
        // Aquí puedes manejar el usuario logueado, token, etc.
      }*/
      // Simulación de un error
      if (state.email.isEmpty || state.password.isEmpty) {
        throw Exception('Email y contraseña son obligatorios');
      }
      // Simulación de un login exitoso
      await Future.delayed(const Duration(seconds: 2));
      // Aquí puedes manejar el usuario logueado, token, etc.
      // Por ejemplo, redirigir a la pantalla de inicio
      context.go('/dashboard');
      // Simulación de un error
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString()) as AuthStateModel;
    } finally {
      state = state.copyWith(loading: false) as AuthStateModel;
    }
  }
}
