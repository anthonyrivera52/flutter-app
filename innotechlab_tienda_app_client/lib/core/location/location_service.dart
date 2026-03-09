import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_result.dart';

/// Abstracted Location Service for better testability and error handling
/// Follows Single Responsibility Principle
class LocationService {
  static const String _lastLocationKey = 'last_known_location';
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration cacheValidity = Duration(minutes: 30);

  final GeolocatorPlatform _geolocator;

  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await _geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await _geolocator.requestPermission();
  }

  /// Get current position with proper error handling
  /// Includes retry logic and timeout handling
  Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeout,
    int maxRetries = 2,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;

    // First check if service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationErrorType.serviceDisabled,
        'Los servicios de ubicación están deshabilitados. Por favor, habilítalos en configuración.',
      );
    }

    // Check and request permission
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationErrorType.permissionDenied,
        'Permiso de ubicación denegado. Concede permiso para encontrar comercios cercanos.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationErrorType.permissionDeniedForever,
        'Permiso de ubicación denegado permanentemente. Cambia los permisos en configuración.',
      );
    }

    // Try to get position with retry logic
    LocationException? lastError;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final position = await _geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            timeLimit: effectiveTimeout,
          ),
        );

        final result = LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        );

        // Cache the successful location
        await _cacheLocation(result);

        return result;
      } catch (e) {
        lastError = LocationException(
          LocationErrorType.timeout,
          'No se pudo obtener la ubicación. Intenta de nuevo.',
        );
        // Wait before retry (exponential backoff)
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    throw lastError ??
        const LocationException(
          LocationErrorType.unknown,
          'Error desconocido al obtener ubicación.',
        );
  }

  /// Get cached location if available and still valid
  Future<LocationResult?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('${_lastLocationKey}_lat');
      final lng = prefs.getDouble('${_lastLocationKey}_lng');
      final timestampMs = prefs.getInt('${_lastLocationKey}_timestamp');

      if (lat == null || lng == null || timestampMs == null) {
        return null;
      }

      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      final age = DateTime.now().difference(timestamp);

      // Return cached location only if still valid
      if (age > cacheValidity) {
        return null;
      }

      return LocationResult(
        latitude: lat,
        longitude: lng,
        timestamp: timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  /// Cache the current location
  Future<void> _cacheLocation(LocationResult location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_lastLocationKey}_lat', location.latitude);
      await prefs.setDouble('${_lastLocationKey}_lng', location.longitude);
      await prefs.setInt(
        '${_lastLocationKey}_timestamp',
        location.timestamp.millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silently fail cache operations
    }
  }

  /// Get last known location without waiting for fresh data
  /// Useful for showing initial UI quickly
  Future<LocationResult?> getLastKnownLocation() async {
    try {
      final position = await _geolocator.getLastKnownPosition();
      if (position == null) return null;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await _geolocator.openLocationSettings();
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    return await _geolocator.openAppSettings();
  }

  /// Calculate distance between two coordinates in kilometers
  /// Uses Haversine formula
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return _geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert meters to km
  }

  /// Check if a location is within service radius of a shop
  bool isWithinServiceRadius(
    double userLat,
    double userLng,
    double shopLat,
    double shopLng,
    double radiusKm,
  ) {
    final distance = calculateDistance(userLat, userLng, shopLat, shopLng);
    return distance <= radiusKm;
  }

  /// Get location accuracy description for UI
  String getAccuracyDescription(double? accuracyMeters) {
    if (accuracyMeters == null) return 'Precisión desconocido';
    if (accuracyMeters <= 10) return 'Precisión alta';
    if (accuracyMeters <= 50) return 'Precisión media';
    if (accuracyMeters <= 100) return 'Precisión baja';
    return 'Precisión muy baja';
  }
}
