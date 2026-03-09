// lib/core/providers/auth_providers.dart

import 'dart:async';

import 'package:delivery_app_mvvm/data/datasources/auth_remote_data_source.dart';
import 'package:delivery_app_mvvm/data/repositories/auth_repository_impl.dart';
// ignore: library_prefixes
import 'package:delivery_app_mvvm/domain/entities/auth_user.dart' as AuthUser;
import 'package:delivery_app_mvvm/domain/usecases/get_auth_session.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_in_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_out_user.dart';
import 'package:delivery_app_mvvm/domain/usecases/sign_up_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_providers.dart';

// ============================================================================
// DATA SOURCES & REPOSITORIES
// ============================================================================

/// Provider para AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AuthRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

/// Provider para AuthRepositoryImpl
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ============================================================================
// USE CASES
// ============================================================================

/// Provider para SignInUser
final signInUserProvider = Provider<SignInUser>((ref) {
  return SignInUser(ref.watch(authRepositoryProvider));
});

/// Provider para SignUpUser
final signUpUserProvider = Provider<SignUpUser>((ref) {
  return SignUpUser(ref.watch(authRepositoryProvider));
});

/// Provider para SignOutUser
final signOutUserProvider = Provider<SignOutUser>((ref) {
  return SignOutUser(ref.watch(authRepositoryProvider));
});

/// Provider para GetAuthSession
final getAuthSessionProvider = Provider<GetAuthSession>((ref) {
  return GetAuthSession(ref.watch(authRepositoryProvider));
});

// ============================================================================
// AUTH STATE
// ============================================================================

/// Estado de autenticación
class AuthState {
  final AuthUser.AuthUser? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    AuthUser.AuthUser? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Notifier para manejar autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUser _signInUser;
  final SignUpUser _signUpUser;
  final SignOutUser _signOutUser;
  final GetAuthSession _getAuthSession;

  StreamSubscription? _authStateSubscription;

  AuthNotifier({
    required SignInUser signInUser,
    required SignUpUser signUpUser,
    required SignOutUser signOutUser,
    required GetAuthSession getAuthSession,
  }) : _signInUser = signInUser,
       _signUpUser = signUpUser,
       _signOutUser = signOutUser,
       _getAuthSession = getAuthSession,
       super(const AuthState()) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authStateSubscription = _getAuthSession.repository.authStateChanges.listen(
      (user) {
        state = state.copyWith(
          currentUser: user,
          errorMessage: null,
          isInitialized: true,
        );
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: 'Error en autenticación: $error',
          isInitialized: true,
        );
      },
    );

    // Verificar sesión actual
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    state = state.copyWith(isLoading: true);
    final result = await _getAuthSession();
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
          isInitialized: true,
        );
      },
      (user) {
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          isInitialized: true,
        );
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signInUser(email, password);
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (user) {
        state = state.copyWith(isLoading: false, currentUser: user);
      },
    );
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signUpUser(email, password);
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          currentUser: user,
          errorMessage:
              '¡Cuenta creada! Por favor, revisa tu correo para confirmar.',
        );
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signOutUser();
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (_) {
        state = state.copyWith(isLoading: false, clearUser: true);
      },
    );
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  String _mapFailureToMessage(dynamic failure) {
    if (failure.toString().contains('AuthFailure')) {
      return failure.message ?? 'Error de autenticación';
    }
    return 'Ocurrió un error inesperado';
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

/// Provider para AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    signInUser: ref.watch(signInUserProvider),
    signUpUser: ref.watch(signUpUserProvider),
    signOutUser: ref.watch(signOutUserProvider),
    getAuthSession: ref.watch(getAuthSessionProvider),
  );
});
