import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_tienda/data/repositories/auth_repository_impl.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_in_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_up_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/send_otp_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/verify_otp_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/update_user_profile_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/upload_profile_image_usecase.dart';
import 'package:mi_tienda/domain/entities/user.dart';
import 'package:mi_tienda/core/errors/failures.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final String? errorMessage;

  AuthState({this.isLoading = false, this.user, this.errorMessage});

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final signInUseCase = ref.watch(signInUseCaseProvider);
  final signUpUseCase = ref.watch(signUpUseCaseProvider);
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  final sendOtpUseCase = ref.watch(sendOtpUseCaseProvider);
  final verifyOtpUseCase = ref.watch(verifyOtpUseCaseProvider);
  final updateUserProfileUseCase = ref.watch(updateUserProfileUseCaseProvider);
  final uploadProfileImageUseCase = ref.watch(uploadProfileImageUseCaseProvider);

  return AuthNotifier(
    signInUseCase,
    signUpUseCase,
    getCurrentUserUseCase,
    sendOtpUseCase,
    verifyOtpUseCase,
    updateUserProfileUseCase,
    uploadProfileImageUseCase,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SendOtpUseCase _sendOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final UploadProfileImageUseCase _uploadProfileImageUseCase;

  AuthNotifier(
    this._signInUseCase,
    this._signUpUseCase,
    this._getCurrentUserUseCase,
    this._sendOtpUseCase,
    this._verifyOtpUseCase,
    this._updateUserProfileUseCase,
    this._uploadProfileImageUseCase,
  ) : super(AuthState()) {
    _loadCurrentUser();
  }

  String? get errorMessage => state.errorMessage;

  Future<void> _loadCurrentUser() async {
    state = state.copyWith(isLoading: true);
    final result = await _getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signInUseCase(SignInParams(email: email, password: password));
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _signUpUseCase(SignUpParams(email: email, password: password));
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<bool> sendOtpForVerification(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _sendOtpUseCase(SendOtpParams(email: email));
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _verifyOtpUseCase(VerifyOtpParams(email: email, otp: otp));
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<bool> updateUserProfile({String? username, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _updateUserProfileUseCase(
      UpdateUserProfileParams(username: username, avatarUrl: avatarUrl),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
        return false;
      },
      (updatedUser) {
        state = state.copyWith(isLoading: false, user: updatedUser);
        return true;
      },
    );
  }

  Future<String?> uploadProfileImage(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _uploadProfileImageUseCase(UploadProfileImageParams(filePath: filePath));
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
        return null;
      },
      (imageUrl) {
        state = state.copyWith(isLoading: false);
        return imageUrl;
      },
    );
  }

  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await ref.read(authRepositoryProvider).signOut(); // Accediendo al repositorio directamente para signOut
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure));
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, user: null);
        return true;
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is AuthFailure) {
      return failure.message;
    } else {
      return 'Ocurrió un error inesperado.';
    }
  }
}