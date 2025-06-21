// lib/viewmodel/home_view_model.dart
import 'package:flutter/foundation.dart';
import '../core/error/failures.dart';
import '../domain/entities/user_status.dart';
import '../domain/usecases/get_user_online_status.dart';
import '../domain/usecases/go_offline.dart';
import 'auth_view_model.dart'; // Import AuthViewModel

class HomeViewModel extends ChangeNotifier {
  final GetUserOnlineStatus _getUserOnlineStatus;
  final GoOnline _goOnline;
  final GoOffline _goOffline;
  final AuthViewModel _authViewModel; // New dependency

  UserStatus _userStatus = UserStatus(status: UserConnectionStatus.offline, message: "You're Offline");
  UserStatus get userStatus => _userStatus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeViewModel({
    required GetUserOnlineStatus getUserOnlineStatus,
    required GoOnline goOnline,
    required GoOffline goOffline,
    required AuthViewModel authViewModel, // New: Require AuthViewModel
  })  : _getUserOnlineStatus = getUserOnlineStatus,
        _goOnline = goOnline,
        _goOffline = goOffline,
        _authViewModel = authViewModel {
    // Listen to AuthViewModel's changes
    _authViewModel.addListener(_onAuthStatusChanged);
  }

  void _onAuthStatusChanged() {
    if (_authViewModel.isAuthenticated) {
      // If user becomes authenticated, attempt to go online or initialize status
      // Only do this if the user was previously offline OR if this is the initial load
      if (_userStatus.status == UserConnectionStatus.offline) {
        initializeStatus(); // Re-evaluate status upon login
      }
    } else {
      // If user logs out, force offline status
      _setUserStatus(UserStatus(status: UserConnectionStatus.offline, message: "You're Offline (Logged Out)"));
    }
  }

  Future<void> initializeStatus() async {
    // Only attempt to get online status if authenticated
    if (!_authViewModel.isAuthenticated) {
      _setUserStatus(UserStatus(status: UserConnectionStatus.offline, message: "Please log in to go online."));
      return;
    }

    _setLoading(true);
    final result = await _getUserOnlineStatus();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (status) => _setUserStatus(status),
    );
    _setLoading(false);
  }

  Future<void> attemptGoOnline() async {
    if (!_authViewModel.isAuthenticated) {
      _setErrorMessage("You must be logged in to go online.");
      return;
    }

    _setLoading(true);
    final result = await _goOnline();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (status) => _setUserStatus(status),
    );
    _setLoading(false);
  }

  Future<void> attemptGoOffline() async {
    if (!_authViewModel.isAuthenticated) {
      _setErrorMessage("You must be logged in to go offline.");
      return;
    }

    _setLoading(true);
    final result = await _goOffline();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (status) => _setUserStatus(status),
    );
    _setLoading(false);
  }

  void _setUserStatus(UserStatus status) {
    _userStatus = status;
    _errorMessage = null; // Clear any previous errors on success
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Error: Please try again later.';
      case CacheFailure:
        return 'Cache Error: Could not retrieve local data.';
      case AuthFailure:
        return (failure as AuthFailure).message; // Use message from AuthFailure
      default:
        return 'Unexpected Error: Please try again.';
    }
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthStatusChanged);
    super.dispose();
  }
}