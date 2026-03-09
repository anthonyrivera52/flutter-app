// lib/service/geofence_service.dart
// Servicio de geofencing para delivery

import 'dart:math';

import 'package:delivery_app_mvvm/model/location_data.dart';

/// Representa una zona de geofencing
class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final GeofenceType type;

  const Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.type,
  });

  bool containsLocation(double lat, double lon) {
    return calculateDistance(lat, lon, latitude, longitude) <= radiusKm;
  }

  double distanceTo(double lat, double lon) {
    return calculateDistance(lat, lon, latitude, longitude);
  }
}

enum GeofenceType {
  restaurant,
  customer,
  deliveryZone,
  restrictedZone,
}

/// Servicio de geofencing para gestión de zonas de delivery
class GeofenceService {
  final List<Geofence> _activeGeofences = [];

  /// Agregar una zona de geofencing
  void addGeofence(Geofence geofence) {
    _activeGeofences.add(geofence);
  }

  /// Remover una zona de geofencing
  void removeGeofence(String id) {
    _activeGeofences.removeWhere((g) => g.id == id);
  }

  /// Obtener todas las zonas activas
  List<Geofence> get activeGeofences => List.unmodifiable(_activeGeofences);

  /// Verificar si una ubicación está dentro de alguna zona
  Geofence? isWithinAnyGeofence(double lat, double lon) {
    for (final geofence in _activeGeofences) {
      if (geofence.containsLocation(lat, lon)) {
        return geofence;
      }
    }
    return null;
  }

  /// Verificar si una ubicación está dentro de una zona específica
  bool isWithinGeofence(String geofenceId, double lat, double lon) {
    final geofence = _activeGeofences.firstWhere(
      (g) => g.id == geofenceId,
      orElse: () => throw Exception('Geofence not found: $geofenceId'),
    );
    return geofence.containsLocation(lat, lon);
  }

  /// Obtener la distancia a la zona más cercana
  double distanceToNearestGeofence(double lat, double lon) {
    if (_activeGeofences.isEmpty) return double.infinity;

    double minDistance = double.infinity;
    for (final geofence in _activeGeofences) {
      final distance = geofence.distanceTo(lat, lon);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  /// Obtener geofences dentro de un radio
  List<Geofence> getGeofencesWithinRadius(double lat, double lon, double radiusKm) {
    return _activeGeofences.where((g) => g.distanceTo(lat, lon) <= radiusKm).toList();
  }

  /// Limpiar todas las zonas
  void clearAll() {
    _activeGeofences.clear();
  }

  /// Obtener geofences por tipo
  List<Geofence> getGeofencesByType(GeofenceType type) {
    return _activeGeofences.where((g) => g.type == type).toList();
  }
}

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
  return calculateDistance(lat1, lon1, lat2, lon2) <= radiusKm;
}

/// Calcula el bearing (dirección) entre dos puntos
double calculateBearing(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final double dLon = _degreesToRadians(lon2 - lon1);
  final double lat1Rad = _degreesToRadians(lat1);
  final double lat2Rad = _degreesToRadians(lat2);

  final double y = sin(dLon) * cos(lat2Rad);
  final double x = cos(lat1Rad) * sin(lat2Rad) -
      sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

  final double bearing = atan2(y, x);
  return (bearing * 180 / pi + 360) % 360;
}

/// Estima el tiempo de llegada en minutos dada la distancia
int estimateTravelTimeMinutes(double distanceKm, {double avgSpeedKmh = 30.0}) {
  if (distanceKm <= 0) return 0;
  final hours = distanceKm / avgSpeedKmh;
  return (hours * 60).round();
}

/// Calcula la ruta más corta (simplificado - sin API externa)
class RouteCalculator {
  /// Calcula una ruta simple entre dos puntos
  static RouteResult calculateRoute(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    final distance = calculateDistance(startLat, startLon, endLat, endLon);
    final bearing = calculateBearing(startLat, startLon, endLat, endLon);
    final duration = estimateTravelTimeMinutes(distance);

    return RouteResult(
      distanceKm: distance,
      durationMinutes: duration,
      bearingDegrees: bearing,
      startPoint: LatLngPoint(startLat, startLon),
      endPoint: LatLngPoint(endLat, endLon),
    );
  }

  /// Calcula la ruta total para un delivery (restaurante -> cliente)
  static RouteResult calculateDeliveryRoute(
    double driverLat,
    double driverLon,
    double restaurantLat,
    double restaurantLon,
    double customerLat,
    double customerLon,
  ) {
    // Ruta 1: Repartidor -> Restaurante
    final toRestaurant = calculateRoute(driverLat, driverLon, restaurantLat, restaurantLon);

    // Ruta 2: Restaurante -> Cliente
    final toCustomer = calculateRoute(restaurantLat, restaurantLon, customerLat, customerLon);

    // Ruta total
    final totalDistance = toRestaurant.distanceKm + toCustomer.distanceKm;
    final totalDuration = toRestaurant.durationMinutes + toCustomer.durationMinutes;

    return RouteResult(
      distanceKm: totalDistance,
      durationMinutes: totalDuration,
      bearingDegrees: toCustomer.bearingDegrees,
      startPoint: LatLngPoint(driverLat, driverLon),
      endPoint: LatLngPoint(customerLat, customerLon),
      segments: [
        RouteSegment(
          from: LatLngPoint(driverLat, driverLon),
          to: LatLngPoint(restaurantLat, restaurantLon),
          distanceKm: toRestaurant.distanceKm,
          durationMinutes: toRestaurant.durationMinutes,
          segmentType: SegmentType.toRestaurant,
        ),
        RouteSegment(
          from: LatLngPoint(restaurantLat, restaurantLon),
          to: LatLngPoint(customerLat, customerLon),
          distanceKm: toCustomer.distanceKm,
          durationMinutes: toCustomer.durationMinutes,
          segmentType: SegmentType.toCustomer,
        ),
      ],
    );
  }
}

class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint(this.latitude, this.longitude);
}

class RouteResult {
  final double distanceKm;
  final int durationMinutes;
  final double bearingDegrees;
  final LatLngPoint startPoint;
  final LatLngPoint endPoint;
  final List<RouteSegment>? segments;

  const RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.bearingDegrees,
    required this.startPoint,
    required this.endPoint,
    this.segments,
  });
}

class RouteSegment {
  final LatLngPoint from;
  final LatLngPoint to;
  final double distanceKm;
  final int durationMinutes;
  final SegmentType segmentType;

  const RouteSegment({
    required this.from,
    required this.to,
    required this.distanceKm,
    required this.durationMinutes,
    required this.segmentType,
  });
}

enum SegmentType {
  toRestaurant,
  toCustomer,
}
