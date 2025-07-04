// lib/viewmodel/home_view_model.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/connectivity_service.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:delivery_app_mvvm/service/real_location_service.dart'; // Asegúrate de que esto es correcto si usas RealLocationService
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

  // NUEVAS DEPENDENCIAS
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  
  // NUEVOS STREAMS Y PROPIEDADES PARA UBICACIÓN Y CONECTIVIDAD
  LocationData? _currentDriverLocation;
  LocationData? get currentDriverLocation => _currentDriverLocation;

  bool _hasInternet = true; // Asume que hay internet al inicio
  bool get hasInternet => _hasInternet;

  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
    // INYECTA LOS NUEVOS SERVICIOS AQUÍ
    required LocationService locationService,
    required ConnectivityService connectivityService,
  })  : _getUserOnlineStatus = getUserOnlineStatus,
        _goOnline = goOnline,
        _goOffline = goOffline,
        _authViewModel = authViewModel,
        _locationService = locationService, // ASIGNACIÓN
        _connectivityService = connectivityService // ASIGNACIÓN 
  {
    _authViewModel.addListener(_onAuthStatusChanged);
    _initEarnings(); // Inicia la carga de ganancias
    _listenForLocationChanges(); // Iniciar escucha de ubicación
    _listenForConnectivityChanges(); // Iniciar escucha de conectividad
    _checkInitialConnectivity(); // Verificar estado inicial de conectividad
    // No llamar initializeStatus aquí, se llamará automáticamente o al logearse.
  }

  // MÉTODO PARA ESCUCHAR CAMBIOS DE UBICACIÓN
  void _listenForLocationChanges() {
    _locationSubscription?.cancel(); // Cancela suscripciones previas si las hay
    _locationSubscription = _locationService.getLocationStream().listen(
      (location) {
        _currentDriverLocation = location;
        notifyListeners();
        // debugPrint('Ubicación actualizada: Lat ${location.latitude}, Lon ${location.longitude}');
      },
      onError: (error) {
        _errorMessage = 'Error en el stream de ubicación: $error';
        notifyListeners();
        debugPrint('Location Stream Error: $error');
      },
    );
  }

  // MÉTODO PARA VERIFICAR CONECTIVIDAD INICIAL
  Future<void> _checkInitialConnectivity() async {
    _hasInternet = await _connectivityService.hasActiveInternetConnection();
    notifyListeners();
  }

  // MÉTODO PARA ESCUCHAR CAMBIOS DE CONECTIVIDAD
  void _listenForConnectivityChanges() {
    _connectivitySubscription?.cancel(); // Cancela suscripciones previas si las hay
    _connectivitySubscription = _connectivityService.onConnectivityChanged().listen((List<ConnectivityResult> results) {
      final bool newStatus = !results.contains(ConnectivityResult.none);
      if (_hasInternet != newStatus) {
        _hasInternet = newStatus;
        notifyListeners();
        debugPrint('Estado de Conectividad cambiado: Tiene Internet = $_hasInternet');
        // Si se pierde la conexión, considera pasar a offline automáticamente.
        if (!newStatus && _userStatus.status == 'online') {
          debugPrint('Conexión perdida, pasando a offline automáticamente...');
          goOffline();
        }
      }
    });
  }

  // Método para inicializar/cargar las ganancias al inicio o al logearse
  void _initEarnings() async {
    if (_authViewModel.isAuthenticated && _supabaseClient.auth.currentUser != null) {
      await _fetchEarnings();
    }
  }

  // Método para obtener las ganancias desde Supabase
  Future<void> _fetchEarnings() async {
    _setLoading(true);
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('total_earnings')
          .eq('id', _supabaseClient.auth.currentUser!.id)
          .single();

      if (response != null && response['total_earnings'] != null) {
        _totalEarnings = (response['total_earnings'] as num).toDouble();
      }
    } catch (e) {
      _setErrorMessage('Error fetching earnings: $e');
      debugPrint("Error fetching earnings: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _onAuthStatusChanged() {
    if (_authViewModel.isAuthenticated) {
      _initEarnings();
      // Si el usuario se autentica, intenta obtener su estado online/offline del backend
      initializeStatus(); // Llama a este para obtener el estado del usuario desde el servidor
      // Asegura que los listeners de ubicación y conectividad estén activos
      _listenForLocationChanges();
      _listenForConnectivityChanges();
    } else {
      // Si el usuario cierra sesión, limpia los datos
      _totalEarnings = 0.0;
      _userStatus = UserStatus.offline("You're Offline");
      _currentDriverLocation = null;
      _errorMessage = null;
      _isLoading = false;
      _hasInternet = true; // Reiniciar asumiendo que el estado es desconocido al deslogear
      notifyListeners();
      // Opcional: cancelar suscripciones si no son necesarias sin sesión
      _locationSubscription?.cancel();
      _connectivitySubscription?.cancel();
    }
  }

  // En HomeViewModel
  Future<void> initializeStatus() async {
      debugPrint("HomeViewModel: initializeStatus() called. Auth isAuthenticated: ${_authViewModel.isAuthenticated}");

      if (!_authViewModel.isAuthenticated) {
        _setUserStatus(UserStatus.offline("Please log in to go online."));
        debugPrint("HomeViewModel: initializeStatus() - Not authenticated, returning.");
        return;
      }

      _setLoading(true); // <-- Debug point 1
      debugPrint("HomeViewModel: _setLoading(true) called for initializeStatus. Current _isLoading: $_isLoading");

      final result = await _getUserOnlineStatus();
      debugPrint("HomeViewModel: _getUserOnlineStatus() completed.");

      result.fold(
        (failure) {
          _setErrorMessage(_mapFailureToMessage(failure));
          debugPrint("HomeViewModel: initializeStatus() - Failure: ${_errorMessage}");
        },
        (status) {
          debugPrint("HomeViewModel: Status from GetUserOnlineStatus: ${status.status} - ${status.message}");
          _setUserStatus(status);
          debugPrint("HomeViewModel: initializeStatus() - Status set.");
        },
      );
      _setLoading(false); // <-- Debug point 2
      debugPrint("HomeViewModel: _setLoading(false) called for initializeStatus. Current _isLoading: $_isLoading");
  }

  // Método para ir online
  Future<void> goOnline() async {
    if (!_authViewModel.isAuthenticated) {
      _setErrorMessage("Please log in to go online.");
      return;
    }
    if (!_hasInternet) {
      _setErrorMessage("No internet connection. Cannot go online.");
      return;
    }
    if (_currentDriverLocation == null) {
      _setErrorMessage("Waiting for your location. Please ensure location services are enabled.");
      // Podrías añadir un delay o un reintento aquí
      return;
    }

    _setLoading(true);
    final result = await _goOnline(); // Usa el caso de uso
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (_) {
        _setUserStatus(UserStatus.online("Online. Waiting for orders..."));
        _errorMessage = null;
      },
    );
    _setLoading(false);
  }

  // Método para ir offline
  Future<void> goOffline() async {
    if (!_authViewModel.isAuthenticated) {
      _setUserStatus(UserStatus.offline("You're Offline."));
      return;
    }
    if (!_hasInternet) {
      _setErrorMessage("No internet connection. Cannot go offline, but your status might be locally offline.");
      _setUserStatus(UserStatus.offline("Offline (No internet)."));
      notifyListeners();
      return;
    }

    _setLoading(true);
    final result = await _goOffline(); // Usa el caso de uso
    result.fold(
      (failure) => _setErrorMessage(_mapFailureToMessage(failure)),
      (_) {
        _setUserStatus(UserStatus.offline("Offline. Tap to go online."));
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

  // En el método _setLoading de HomeViewModel
  void _setLoading(bool loading) {
      debugPrint("HomeViewModel: _setLoading($loading) called. Old _isLoading: $_isLoading, New _isLoading: $loading");
      _isLoading = loading;
      notifyListeners();
      debugPrint("HomeViewModel: notifyListeners() called after _setLoading($loading).");
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
    debugPrint('HomeViewModel DISPOSING...');
    _authViewModel.removeListener(_onAuthStatusChanged);
    _locationSubscription?.cancel(); // CANCELAR SUSCRIPCIÓN DE UBICACIÓN
    _connectivitySubscription?.cancel(); // CANCELAR SUSCRIPCIÓN DE CONECTIVIDAD
    // Si tus servicios de ubicación/conectividad tienen un dispose, llámalo aquí.
    // Esto es importante si RealLocationService, por ejemplo, gestiona recursos del sistema.
    if (_locationService is RealLocationService) {
      (_locationService as RealLocationService).dispose();
      debugPrint('RealLocationService disposed.');
    }
    super.dispose();
  }
}