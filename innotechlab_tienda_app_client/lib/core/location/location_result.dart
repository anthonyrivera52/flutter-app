import 'package:equatable/equatable.dart';

/// Result wrapper for location operations
/// Following Either pattern for explicit error handling
class LocationResult extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, timestamp];

  /// Calculate distance to another location in kilometers
  /// Uses Haversine formula for accuracy
  double distanceTo(LocationResult other) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);

    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(latitude)) *
            _cos(_toRadians(other.latitude)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorCos(x);
  double _sqrt(double x) => _newtonSqrt(x);
  double _atan2(double y, double x) => _approximateAtan2(y, x);

  // Taylor series approximations for math functions
  double _taylorSin(double x) {
    // Normalize x to [-π, π]
    const double pi = 3.141592653589793;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    if (x < -pi) x += 2 * pi;

    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  double _taylorCos(double x) {
    const double pi = 3.141592653589793;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    if (x < -pi) x += 2 * pi;

    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approximateAtan2(double y, double x) {
    if (x == 0) {
      if (y > 0) return pi / 2;
      if (y < 0) return -pi / 2;
      return 0;
    }
    double atan = _approximateAtan(y / x);
    if (x < 0) {
      if (y >= 0) return atan + pi;
      return atan - pi;
    }
    return atan;
  }

  double _approximateAtan(double x) {
    // Use polynomial approximation for atan
    if (x > 1) return pi / 2 - _approximateAtan(1 / x);
    if (x < -1) return -pi / 2 - _approximateAtan(1 / x);

    double result = x;
    double term = x;
    for (int n = 1; n <= 15; n++) {
      term *= -x * x;
      result += term / (2 * n + 1);
    }
    return result;
  }

  static const double pi = 3.141592653589793;
}

/// Error types for location operations
enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// Custom exception for location errors
class LocationException implements Exception {
  final LocationErrorType type;
  final String message;

  const LocationException(this.type, this.message);

  @override
  String toString() => 'LocationException($type): $message';

  bool get isRetryable =>
      type == LocationErrorType.timeout ||
      type == LocationErrorType.serviceDisabled;
}
