import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double? speed; // Velocidad en m/s (opcional)
  final double? accuracy; // Precisión de la ubicación en metros (opcional)
  final String? address; // Changed to be optional
  final DateTime? timestamp; // Now optional

  LocationData({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.accuracy,
    this.address,
    this.timestamp
  });

  // Convierte a LatLng para usar con Maps_flutter
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?, // Adjusted to be optional
    );
  }

  // Método de fábrica para crear desde LatLng
  factory LocationData.fromLatLng(LatLng latLng, {String? address}) {
    // Allows providing an address or leaving it null
    return LocationData(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      address: address,
      timestamp: DateTime.now()
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'address': address, // Now optional
    };
  }

  @override
  String toString() {
    return 'LocationData(latitude: $latitude, longitude: $longitude, speed: $speed, accuracy: $accuracy, address: $address, timestamp: $timestamp)';
  }
}