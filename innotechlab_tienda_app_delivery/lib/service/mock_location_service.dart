import 'dart:async';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MockLocationService implements LocationService {
  // Simulamos una ruta simple desde Sabaneta (cerca de la ubicación actual del repartidor)
  // hasta un restaurante y luego a un cliente.
  // Estas coordenadas deben coincidir o estar cerca de las coordenadas mock que usas en Order.
  static final List<LatLng> _mockRoutePoints = [
    const LatLng(6.195618, -75.575971), // Punto de inicio (Sabaneta)
    const LatLng(6.185000, -75.580000), // Punto intermedio 1
    const LatLng(6.167885, -75.589885), // Restaurante (ORD001)
    const LatLng(6.170000, -75.585000), // Punto intermedio 2
    const LatLng(6.177000, -75.578000), // Cliente (ORD001)
    const LatLng(6.180000, -75.575000), // Punto intermedio 3
    const LatLng(6.195618, -75.575971), // De vuelta al inicio (para un nuevo pedido)
  ];

  int _currentPointIndex = 0;
  final StreamController<LocationData> _locationStreamController =
      StreamController<LocationData>.broadcast();
  Timer? _timer;

  MockLocationService() {
    _startSimulatedMovement();
  }

  void _startSimulatedMovement() {
    // Emite una nueva ubicación cada 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPointIndex < _mockRoutePoints.length) {
        final currentLatLng = _mockRoutePoints[_currentPointIndex];
        final locationData = LocationData.fromLatLng(currentLatLng);
        _locationStreamController.add(locationData);
        _currentPointIndex++;
      } else {
        // Reinicia la ruta para simular movimiento continuo en un ciclo
        _currentPointIndex = 0;
      }
    });
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    // Simula una pequeña demora para obtener la ubicación
    await Future.delayed(const Duration(seconds: 1));
    // Devuelve la ubicación actual del punto simulado
    return LocationData.fromLatLng(_mockRoutePoints[_currentPointIndex % _mockRoutePoints.length]);
  }

  @override
  Stream<LocationData> getLocationStream() {
    return _locationStreamController.stream;
  }

  // Asegúrate de cerrar el stream y el timer cuando ya no se necesite
  void dispose() {
    _timer?.cancel();
    _locationStreamController.close();
  }
}