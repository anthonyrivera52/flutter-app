class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordObscured;
  final bool isAuthenticated; // Para indicar si la autenticación fue exitosa

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordObscured = true,
    this.isAuthenticated = false,
  });
}