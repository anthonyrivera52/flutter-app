// lib/viewmodel/auth_view_model.dart

import 'package:flutter/foundation.dart';
import 'dart:async'; // ¡Asegúrate de que esta importación esté presente para StreamSubscription!

import '../core/error/failures.dart';
import '../domain/entities/auth_user.dart' as AuthUser;
import '../domain/usecases/sign_in_user.dart';
import '../domain/usecases/sign_up_user.dart';
import '../domain/usecases/sign_out_user.dart';
import '../domain/usecases/get_auth_session.dart';

class AuthViewModel extends ChangeNotifier {
  final SignInUser _signInUser;
  final SignUpUser _signUpUser;
  final SignOutUser _signOutUser;
  final GetAuthSession _getAuthSession;

  AuthUser.AuthUser? _currentUser;
  AuthUser.AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // CAMBIO AQUÍ: Declarar _authStateSubscription como `late StreamSubscription`
  // Esto permite que Dart infiera el tipo exacto de la suscripción en tiempo de ejecución,
  // evitando el error de subtipo con las implementaciones internas de StreamSubscription.
  late StreamSubscription _authStateSubscription;

  AuthViewModel({
    required SignInUser signInUser,
    required SignUpUser signUpUser,
    required SignOutUser signOutUser,
    required GetAuthSession getAuthSession,
  })  : _signInUser = signInUser,
        _signUpUser = signUpUser,
        _signOutUser = signOutUser,
        _getAuthSession = getAuthSession;

  void initializeAuthListener() {
    // Al hacer `.listen()`, la suscripción resultante puede tener un tipo interno complejo.
    // Al declararla como `late StreamSubscription`, evitamos el error de subtipo.
    _authStateSubscription = _getAuthSession.repository.authStateChanges.listen((user) {
      _currentUser = user;
      _errorMessage = null; // Limpiar errores previos al cambiar el estado de auth
      notifyListeners();
    },
    onError: (error) {
      // Es buena práctica añadir manejo de errores para el stream
      _errorMessage = 'Error en el flujo de autenticación: ${error.toString()}';
      notifyListeners();
      print('DEBUG: Error en el stream de AuthState: $error');
    },
    onDone: () {
      print('DEBUG: Stream de AuthState cerrado.');
    });

    // También comprueba la sesión inicial al iniciar la aplicación
    _checkCurrentSession();
  }

  // Verifica la sesión actual al inicio de la app
  Future<void> _checkCurrentSession() async {
    _setLoading(true);
    final result = await _getAuthSession();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (user) {
        _currentUser = user;
        _errorMessage = null;
      },
    );
    _setLoading(false);
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _setErrorMessage(null);
    final result = await _signInUser(email, password);
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (user) {
        _currentUser = user;
      },
    );
    _setLoading(false);
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    _setErrorMessage(null);
    final result = await _signUpUser(email, password);
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (user) {
        _currentUser = user;
        _setErrorMessage("¡Cuenta creada! Por favor, revisa tu correo para confirmar.");
      },
    );
    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    _setErrorMessage(null);
    final result = await _signOutUser();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (_) {
        _currentUser = null;
      },
    );
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is AuthFailure) {
      return failure.message;
    } else if (failure is ServerFailure) {
      return 'Error del servidor durante la autenticación.';
    }
    return 'Ocurrió un error inesperado.';
  }

  @override
  void dispose() {
    // Con `late`, ya no necesitas el operador `?` de nulabilidad al cancelar.
    _authStateSubscription.cancel();
    super.dispose();
  }
}