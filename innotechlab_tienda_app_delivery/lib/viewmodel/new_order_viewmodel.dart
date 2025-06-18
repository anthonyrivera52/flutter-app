import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/service/order_service.dart';
import 'package:delivery_app_mvvm/service/mock_order_service.dart'; // Usamos el mock

// ViewModel para la pantalla de notificación de nueva orden
class NewOrderViewModel extends ChangeNotifier {
  final OrderService _orderService = MockOrderService(); // Inyecta tu servicio
  Order? _currentNewOrder;
  bool _isLoading = false;
  String? _errorMessage;

  Order? get currentNewOrder => _currentNewOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor
  NewOrderViewModel() {
    // Puedes iniciar la búsqueda de órdenes aquí o cuando la vista lo pida
    fetchNewOrder();
  }

  // Método para buscar una nueva orden
  Future<void> fetchNewOrder() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.fetchNewOrder();
      _currentNewOrder = order;
    } catch (e) {
      _errorMessage = 'Error al cargar nueva orden: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para aceptar una orden
  Future<bool> acceptOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderService.updateOrderStatus(orderId, 'accepted');
      _currentNewOrder = _currentNewOrder?.copyWith(status: 'accepted');
      return true;
    } catch (e) {
      _errorMessage = 'Error al aceptar orden: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para rechazar una orden
  Future<bool> rejectOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderService.updateOrderStatus(orderId, 'rejected');
      _currentNewOrder = null; // Limpiamos la orden actual
      return true;
    } catch (e) {
      _errorMessage = 'Error al rechazar orden: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar la orden actual (ej. después de aceptar/rechazar y navegar)
  void clearCurrentOrder() {
    _currentNewOrder = null;
    notifyListeners();
  }
}