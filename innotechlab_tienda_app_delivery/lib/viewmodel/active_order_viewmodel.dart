import 'dart:async'; // Necesario para StreamSubscription
import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/model/location_data.dart'; // Importa LocationData
import 'package:delivery_app_mvvm/service/order_service.dart';
import 'package:delivery_app_mvvm/service/mock_order_service.dart';
import 'package:delivery_app_mvvm/service/location_service.dart'; // Importa la interfaz del servicio de ubicación
import 'package:delivery_app_mvvm/service/mock_location_service.dart'; // Importa el servicio mock de ubicación

class ActiveOrderViewModel extends ChangeNotifier {
  final OrderService _orderService = MockOrderService();
  final LocationService _locationService = MockLocationService(); // Inyecta el servicio de ubicación

  Order? _activeOrder;
  bool _isLoading = false;
  String? _errorMessage;
  LocationData? _currentDriverLocation; // Nueva propiedad para la ubicación del repartidor

  StreamSubscription<LocationData>? _locationSubscription; // Suscripción para el stream de ubicación

  Order? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LocationData? get currentDriverLocation => _currentDriverLocation; // Getter para la ubicación

  // Constructor
  ActiveOrderViewModel() {
    _startListeningToLocation();
  }

  void _startListeningToLocation() {
    _locationSubscription = _locationService.getLocationStream().listen(
      (location) {
        _currentDriverLocation = location;
        notifyListeners(); // Notifica a los listeners cada vez que la ubicación cambia
      },
      onError: (error) {
        _errorMessage = 'Error en el stream de ubicación: $error';
        notifyListeners();
      },
    );
  }

  // Establece la orden que está actualmente activa para el repartidor
  void setActiveOrder(Order order) {
    _activeOrder = order;
    // Si la orden cambia, podrías querer centrar el mapa, etc.
    notifyListeners();
  }

  // Actualiza el estado de la orden (ej. 'picking_up', 'delivering', 'delivered')
  Future<void> updateOrderStatus(String newStatus) async {
    if (_activeOrder == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.updateOrderStatus(_activeOrder!.id, newStatus);
      _activeOrder = _activeOrder!.copyWith(status: newStatus); // Actualiza el estado local
    } catch (e) {
      _errorMessage = 'Error al actualizar estado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simula la finalización de una orden activa
  void completeActiveOrder() {
    _activeOrder = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel(); // Cancela la suscripción al stream para evitar fugas de memoria
    (_locationService as MockLocationService).dispose(); // Llama al dispose del mock
    super.dispose();
  }
}