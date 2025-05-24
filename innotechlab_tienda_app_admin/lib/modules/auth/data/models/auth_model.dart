import 'package:flutter_app/modules/auth/domain/entities/auth.dart';

class AuthStateModel extends AuthState {

  AuthState copyWith({
    String? email,
    String? password,
    bool? loading,
    String? errorMessage,
  }) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
    );
  }
}