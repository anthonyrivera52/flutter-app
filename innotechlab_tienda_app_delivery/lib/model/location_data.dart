import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double? speed; // Velocidad en m/s (opcional)
  final double? accuracy; // Precisión de la ubicación en metros (opcional)
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.accuracy,
    required this.address
  });

  // Convierte a LatLng para usar con Maps_flutter
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

   factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
    );
  }

  // Método de fábrica para crear desde LatLng
  factory LocationData.fromLatLng(LatLng latLng) {
    return LocationData(latitude: latLng.latitude, longitude: latLng.longitude, address: '');
  }
}