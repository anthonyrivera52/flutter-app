import 'dart:async';

import 'package:delivery_app_mvvm/main.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/service/order_service.dart';
import 'package:delivery_app_mvvm/service/mock_order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Usamos el mock

// ViewModel para la pantalla de notificación de nueva orden
class NewOrderViewModel extends ChangeNotifier {
  final OrderService _orderService = MockOrderService(); // Inyecta tu servicio
  Order? _currentNewOrder;
  bool _isLoading = false;
  String? _errorMessage;

  Order? get currentNewOrder => _currentNewOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  // ignore: unused_field
  StreamSubscription<List<Map<String, dynamic>>>? _orderSubscription;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Constructor
  NewOrderViewModel() {
    // Puedes iniciar la búsqueda de órdenes aquí o cuando la vista lo pida
    fetchNewOrder();
  }

  // En tu NewOrderViewModel
Future<void> fetchNewOrder() async { // O _listenForNewOrders()
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    debugPrint('--> Initiating Supabase stream for orders...');
    _orderSubscription = _supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1)
        .listen((List<Map<String, dynamic>> data) {
          debugPrint('--> Supabase stream data received: $data'); // <--- ¡MIRAR ESTO EN LA CONSOLA!
          if (data.isNotEmpty) {
            final newOrderData = data.first;
            final Order newOrder = Order.fromJson(newOrderData);

            // Aquí puedes añadir un debugPrint para la orden antes de la notificación
            debugPrint('--> Parsed Order: ID=${newOrder.id}, Customer=${newOrder.customerName}, Status=${newOrder.status}');

            if (_currentNewOrder == null || _currentNewOrder!.id != newOrder.id) {
              notifyListeners();
              _currentNewOrder = newOrder;
              notificationService.showNotification(
                id: 0,
                title: '¡Nuevo Pedido Recibido!',
                body: 'Pedido para ${newOrder.customerName} a ${newOrder.customerAddress}. Total: \$${newOrder.totalAmount.toStringAsFixed(2)}',
                payload: newOrder.id,
              );
              debugPrint('--> Notification triggered for order: ${newOrder.id}');
            } else {
              debugPrint('--> Order ${newOrder.id} already processed or is the same, skipping notification.');
            }
          } else {
            debugPrint('--> Supabase stream received empty data or no matching pending orders.');
          }
        }, onError: (error) {
          _errorMessage = 'Error en Realtime de Supabase: $error';
          debugPrint('--> Supabase Stream ERROR: $error'); // <--- ¡MIRAR ESTO EN LA CONSOLA!
          _isLoading = false;
          notifyListeners();
        }, onDone: () {
          debugPrint('--> Supabase Stream: Listener completed. (This should not happen for a continuous stream)');
        });
  } catch (e) {
    _errorMessage = 'Error al iniciar la suscripción: $e';
    debugPrint('--> Supabase Stream Setup ERROR: $e');
  } finally {
    _isLoading = false; // El loading se desactiva una vez que el setup se completa, no cuando llegan datos
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