// lib/viewmodel/home_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/error/failures.dart';
import '../domain/entities/user_status.dart';
import '../domain/usecases/get_user_online_status.dart';
import '../domain/usecases/go_offline.dart';
import 'auth_view_model.dart'; // Import AuthViewModel

class HomeViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  final GetUserOnlineStatus _getUserOnlineStatus;
  final GoOnline _goOnline;
  final GoOffline _goOffline;
  final AuthViewModel _authViewModel; // New dependency

  // New property for total earnings
  double _totalEarnings = 0.0;

  UserStatus _userStatus = UserStatus(status: UserConnectionStatus.offline, message: "You're Offline");
  UserStatus get userStatus => _userStatus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  double get totalEarnings => _totalEarnings; // Getter for total earnings

  HomeViewModel(this._supabaseClient,{
    required GetUserOnlineStatus getUserOnlineStatus,
    required GoOnline goOnline,
    required GoOffline goOffline,
    required AuthViewModel authViewModel,
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
    _loadInitialEarnings(); // Load earnings when ViewModel is created
  }

  Future<void> _loadInitialEarnings() async {
    try {
      final response = await _supabaseClient
          .from('profiles') // Assuming you have a 'profiles' table linked to users
          .select('total_earnings')
          .eq('id', _supabaseClient.auth.currentUser!.id)
          .single();

      if (response.isNotEmpty && response['total_earnings'] != null) {
        _totalEarnings = (response['total_earnings'] as num).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading initial earnings: $e");
      // Optionally set an error message
    }
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

    // Method to add to total earnings
  void addEarnings(double amount) {
    _totalEarnings += amount;
    notifyListeners();
    // Optionally, persist this value (e.g., to SharedPreferences or Supabase)
    _persistEarnings(_totalEarnings);
  }

    // Persist earnings to storage
  Future<void> _persistEarnings(double earnings) async {
    try {
      await _supabaseClient
          .from('profiles') // Assuming you have a 'profiles' table
          .update({'total_earnings': earnings})
          .eq('id', _supabaseClient.auth.currentUser!.id);
      debugPrint("Earnings persisted: $earnings");
      print("Earnings persisted: $earnings");
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