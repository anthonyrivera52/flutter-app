import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/location/location_service.dart';
import '../../core/location/location_result.dart';

/// Provider for LocationService - singleton pattern
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for current location with caching
final currentLocationProvider = FutureProvider<LocationResult?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);

  // Try to get cached location first for quick UI
  final cached = await locationService.getCachedLocation();
  if (cached != null) {
    return cached;
  }

  // Try last known position
  final lastKnown = await locationService.getLastKnownLocation();
  if (lastKnown != null) {
    return lastKnown;
  }

  // Get fresh location
  try {
    return await locationService.getCurrentPosition();
  } catch (e) {
    return null;
  }
});

/// State for location tracking
class LocationState {
  final LocationResult? currentLocation;
  final bool isLoading;
  final String? errorMessage;
  final bool hasPermission;
  final double? accuracy;

  const LocationState({
    this.currentLocation,
    this.isLoading = false,
    this.errorMessage,
    this.hasPermission = false,
    this.accuracy,
  });

  LocationState copyWith({
    LocationResult? currentLocation,
    bool? isLoading,
    String? errorMessage,
    bool? hasPermission,
    double? accuracy,
    bool clearError = false,
    bool clearLocation = false,
  }) {
    return LocationState(
      currentLocation: clearLocation ? null : (currentLocation ?? this.currentLocation),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasPermission: hasPermission ?? this.hasPermission,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  /// Get human-readable accuracy
  String get accuracyDescription {
    final locationService = LocationService();
    return locationService.getAccuracyDescription(accuracy);
  }

  /// Check if location is stale (older than 30 minutes)
  bool get isLocationStale {
    if (currentLocation == null) return true;
    final age = DateTime.now().difference(currentLocation!.timestamp);
    return age.inMinutes > 30;
  }
}

/// Notifier for location state management
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const LocationState());

  /// Request location permission
  Future<bool> requestPermission() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final permission = await _locationService.requestPermission();
      final hasPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      state = state.copyWith(
        isLoading: false,
        hasPermission: hasPermission,
      );

      return hasPermission;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al solicitar permisos: $e',
      );
      return false;
    }
  }

  /// Get current location with proper error handling
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final location = await _locationService.getCurrentPosition();

      state = state.copyWith(
        isLoading: false,
        currentLocation: location,
        accuracy: location.accuracy,
        hasPermission: true,
      );
    } on LocationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener ubicación: $e',
      );
    }
  }

  /// Refresh location
  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }

  /// Open device settings
  Future<void> openSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Check if location is within radius of a shop
  bool isWithinRadius(double shopLat, double shopLng, double radiusKm) {
    if (state.currentLocation == null) return false;
    return _locationService.isWithinServiceRadius(
      state.currentLocation!.latitude,
      state.currentLocation!.longitude,
      shopLat,
      shopLng,
      radiusKm,
    );
  }

  /// Get distance to a point in km
  double? distanceTo(double lat, double lng) {
    if (state.currentLocation == null) return null;
    return _locationService.calculateDistance(
      state.currentLocation!.latitude,
      state.currentLocation!.longitude,
      lat,
      lng,
    );
  }
}

/// Provider for location state
final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});
