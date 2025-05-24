class AuthState {
  final String email;
  final String password;
  final bool loading;
  final String? errorMessage;

  AuthState({
    this.email = '',
    this.password = '',
    this.loading = false,
    this.errorMessage,
  });
}