import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/user.dart';
import 'package:mi_tienda/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_in_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_out_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_up_usecase.dart';
import 'package:mi_tienda/service_locator.dart';

// Estado de autenticación
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Proveedor de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final signInUseCase = ref.watch(signInUseCaseProvider);
  final signUpUseCase = ref.watch(signUpUseCaseProvider);
  final signOutUseCase = ref.watch(signOutUseCaseProvider);
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

  return AuthNotifier(
    signInUseCase,
    signUpUseCase,
    signOutUseCase,
    getCurrentUserUseCase,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthNotifier(
    this._signInUseCase,
    this._signUpUseCase,
    this._signOutUseCase,
    this._getCurrentUserUseCase,
  ) : super(const AuthState()) {
    _initAuthListener();
  }
  
  get ref => null;

  void _initAuthListener() {
    final authRepo = ref.read(authRepositoryProvider);
    authRepo.authStateChanges.listen((user) {
      if (user != null) {
        state = state.copyWith(isAuthenticated: true, user: user, isLoading: false, errorMessage: null);
      } else {
        state = state.copyWith(isAuthenticated: false, user: null, isLoading: false, errorMessage: null);
      }
    });

    _getCurrentUserUseCase(const NoParams()).then((result) {
      result.fold(
        (failure) {
          state = state.copyWith(isAuthenticated: false, user: null, isLoading: false, errorMessage: null);
        },
        (user) {
          state = state.copyWith(isAuthenticated: true, user: user, isLoading: false, errorMessage: null);
        },
      );
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signInUseCase(SignInParams(email: email, password: password));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (user) => state = state.copyWith(isLoading: false, isAuthenticated: true, user: user),
    );
  }

  Future<void> signUp({required String email, required String password, String? displayName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signUpUseCase(
      SignUpParams(email: email, password: password, displayName: displayName),
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (user) => state = state.copyWith(isLoading: false, isAuthenticated: true, user: user),
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signOutUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (_) => state = state.copyWith(isLoading: false, isAuthenticated: false, user: null),
    );
  }

  // Este método requeriría un nuevo UseCase y lógica en el repositorio/datasource
  // para actualizar el perfil del usuario en Supabase (ej. displayName, avatarUrl)
  Future<void> updateUserProfile({String? displayName, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // Simulación de actualización
    await Future.delayed(const Duration(seconds: 1));
    if (state.user != null) {
      state = state.copyWith(
        isLoading: false,
        user: state.user!.copyWith(displayName: displayName, avatarUrl: avatarUrl),
      );
    } else {
      state = state.copyWith(isLoading: false, errorMessage: 'No user authenticated to update.');
    }
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
