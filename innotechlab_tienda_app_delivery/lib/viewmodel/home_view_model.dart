// lib/viewmodel/home_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/error/failures.dart';
import '../domain/usecases/get_user_online_status.dart';
import '../domain/usecases/go_offline.dart';
import '../domain/entities/user_status.dart'; // This is the CORRECT UserStatus
import 'auth_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  final GetUserOnlineStatus _getUserOnlineStatus;
  final GoOnline _goOnline;
  final GoOffline _goOffline;
  final AuthViewModel _authViewModel;

  double _totalEarnings = 0.0;

  // Use the UserStatus from '../domain/entities/user_status.dart'
  UserStatus _userStatus = UserStatus.offline("You're Offline"); // Using factory constructor
  UserStatus get userStatus => _userStatus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  double get totalEarnings => _totalEarnings;

  HomeViewModel(this._supabaseClient,{
    required GetUserOnlineStatus getUserOnlineStatus,
    required GoOnline goOnline,
    required GoOffline goOffline,
    required AuthViewModel authViewModel,
  })  : _getUserOnlineStatus = getUserOnlineStatus,
        _goOnline = goOnline,
        _goOffline = goOffline,
        _authViewModel = authViewModel {
    _authViewModel.addListener(_onAuthStatusChanged);
    _onAuthStatusChanged(); // Call it once to set initial status
  }

  void _onAuthStatusChanged() {
    debugPrint("HomeViewModel: Auth status changed. Is authenticated: ${_authViewModel.isAuthenticated}");
    if (_authViewModel.isAuthenticated) {
      if (_userStatus.status == UserConnectionStatus.offline || _userStatus.status == UserConnectionStatus.error) {
        initializeStatus();
      }
    } else {
      _setUserStatus(UserStatus.offline("You're Offline (Logged Out)")); // Using factory constructor
    }
  }

  Future<void> initializeStatus() async {
    if (!_authViewModel.isAuthenticated) {
      _setUserStatus(UserStatus.offline("Please log in to go online.")); // Using factory constructor
      return;
    }

    _setLoading(true);
    final result = await _getUserOnlineStatus();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (status) {
        // [FIX] Removed the explicit 'as UserStatus' cast.
        // The 'status' parameter here is already correctly typed as UserStatus
        // by the 'Right' side of the 'Either' from the use case.
        debugPrint("HomeViewModel: Status from GetUserOnlineStatus: ${status.status} - ${status.message}");
        _setUserStatus(status);
      },
    );
    _setLoading(false);
    _loadInitialEarnings();
  }

  Future<void> _loadInitialEarnings() async {
    if (!_authViewModel.isAuthenticated || _supabaseClient.auth.currentUser == null) {
      debugPrint("HomeViewModel: Cannot load earnings, user not authenticated.");
      return;
    }
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('total_earnings')
          .eq('id', _supabaseClient.auth.currentUser!.id)
          .single();

      if (response.isNotEmpty && response['total_earnings'] != null) {
        _totalEarnings = (response['total_earnings'] as num).toDouble();
        notifyListeners();
        debugPrint("HomeViewModel: Initial earnings loaded: $_totalEarnings");
      } else {
         debugPrint("HomeViewModel: No initial earnings found or response empty.");
      }
    } catch (e) {
      debugPrint("Error loading initial earnings: $e");
    }
  }

  Future<void> attemptGoOnline() async {
    if (!_authViewModel.isAuthenticated) {
      _setErrorMessage("Please log in to go online.");
      return;
    }
    _setLoading(true);
    final result = await _goOnline();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (_) {
        _setUserStatus(UserStatus.online("Online. Waiting for orders...")); // Using factory constructor
        _errorMessage = null;
      },
    );
    _setLoading(false);
  }

  Future<void> attemptGoOffline() async {
    if (!_authViewModel.isAuthenticated) {
      _setUserStatus(UserStatus.offline("You're Offline.")); // Using factory constructor
      return;
    }
    _setLoading(true);
    final result = await _goOffline();
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (_) {
        _setUserStatus(UserStatus.offline("Offline. Tap to go online.")); // Using factory constructor
        _errorMessage = null;
      },
    );
    _setLoading(false);
  }

  void _setUserStatus(UserStatus status) {
    debugPrint("HomeViewModel: Cambiando userStatus a: ${status.status} con mensaje: ${status.message}");
    _userStatus = status;
    _errorMessage = null;
    notifyListeners();
  }

  void addEarnings(double amount) {
    _totalEarnings += amount;
    notifyListeners();
    _persistEarnings(_totalEarnings);
  }

  Future<void> _persistEarnings(double earnings) async {
    if (!_authViewModel.isAuthenticated || _supabaseClient.auth.currentUser == null) {
      debugPrint("HomeViewModel: Cannot persist earnings, user not authenticated.");
      return;
    }
    try {
      await _supabaseClient
          .from('profiles')
          .update({'total_earnings': earnings})
          .eq('id', _supabaseClient.auth.currentUser!.id);
      debugPrint("Earnings persisted: $earnings");
    } catch (e) {
      debugPrint("Error persisting earnings: $e");
    }
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
        return (failure as AuthFailure).message;
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