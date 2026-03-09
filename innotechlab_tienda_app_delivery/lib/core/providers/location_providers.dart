// lib/core/providers/location_providers.dart

import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery_app_mvvm/domain/entities/user_status.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/connectivity_service.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:delivery_app_mvvm/service/real_location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// PROVIDERS BÁSICOS DE SERVICIOS
// ============================================================================

/// Provider para el servicio de ubicación
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = RealLocationService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider para el servicio de conectividad
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// ============================================================================
// PROVIDERS DE ESTADO DE UBICACIÓN
// ============================================================================

/// Provider que emite stream de ubicación actual del repartidor
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getLocationStream();
});

/// Provider para obtener la última ubicación conocida
final currentLocationProvider = StateProvider<LocationData?>((ref) {
  return null;
});

// ============================================================================
// PROVIDERS DE CONECTIVIDAD
// ============================================================================

/// Provider de estado de conectividad (bool)
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return ConnectivityNotifier(connectivityService);
});

class ConnectivityNotifier extends StateNotifier<bool> {
  final ConnectivityService _connectivityService;

  ConnectivityNotifier(this._connectivityService) : super(true) {
    _init();
  }

  Future<void> _init() async {
    // Verificar estado inicial
    state = await _connectivityService.hasActiveInternetConnection();

    // Escuchar cambios
    _connectivityService.onConnectivityChanged().listen((results) {
      final newState = !results.contains(ConnectivityResult.none);
      if (state != newState) {
        state = newState;
      }
    });
  }

  Future<void> checkConnectivity() async {
    state = await _connectivityService.hasActiveInternetConnection();
  }
}

// ============================================================================
// PROVIDERS DE ESTADO DEL REPARTIDOR (ONLINE/OFFLINE)
// ============================================================================

/// Provider para el estado online/offline del repartidor
/// Usa la clase UserStatus del dominio
final userStatusProvider = StateNotifierProvider<UserStatusNotifier, UserStatus>((ref) {
  return UserStatusNotifier();
});

class UserStatusNotifier extends StateNotifier<UserStatus> {
  UserStatusNotifier() : super(UserStatus.offline("You're Offline"));

  void goOnline([String message = 'Online. Waiting for orders...']) {
    state = UserStatus.online(message);
  }

  void goOffline([String message = "You're Offline"]) {
    state = UserStatus.offline(message);
  }

  void setError([String message = 'Error']) {
    state = UserStatus.error(message);
  }
}

// ============================================================================
// GEOLOCALIZACIÓN - HELPERS
// ============================================================================

/// Calcula la distancia entre dos puntos usando la fórmula de Haversine
/// Retorna la distancia en kilómetros
double calculateDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

/// Verifica si un punto está dentro de un radio determinado
bool isWithinRadius(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
  double radiusKm,
) {
  final distance = calculateDistance(lat1, lon1, lat2, lon2);
  return distance <= radiusKm;
}

/// Provider para el radio máximo de geofencing (en km)
final maxGeofenceRadiusProvider = StateProvider<double>((ref) => 5.0);
