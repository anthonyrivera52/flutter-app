// lib/viewmodel/new_order_viewmodel.dart

import 'dart:async';

import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewOrderViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _orderSubscription;
  final NotificationService notificationService; // Asegúrate de que esto se inyecte

  Order? _currentNewOrder;
  Order? get currentNewOrder => _currentNewOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor
  NewOrderViewModel(this._supabaseClient, this.notificationService) {
    _listenForNewOrders(); // Inicia la escucha al construir el ViewModel
  }

  Future<bool> acceptOrder(String orderId) async {
    debugPrint('Attempting to accept order: $orderId');
    await updateOrderStatus(orderId, 'accepted'); // Update status in Supabase
    // The Realtime listener should automatically clear _currentNewOrder if the filter excludes 'accepted'
    // But we can also manually clear it if preferred for immediate UI response.
    clearCurrentNewOrder(); // Clear the alert from the UI
    return true;
  }

  Future<bool> rejectOrder(String orderId) async {
    debugPrint('Attempting to reject order: $orderId');
    await updateOrderStatus(orderId, 'rejected'); // Update status in Supabase
    clearCurrentNewOrder(); // Clear the alert from the UI
    return true;
  }

  // Método para buscar una nueva orden (realmente, inicia el listener)
  Future<void> fetchNewOrder() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Si ya hay una suscripción, la cancelamos para iniciar una nueva
    // (Útil si se llama fetchNewOrder más de una vez, aunque _listenForNewOrders
    // ya debería manejar esto si solo se llama en el constructor)
    _orderSubscription?.cancel();
    _listenForNewOrders(); // Reinicia la escucha

    _isLoading = false; // El loading se desactiva una vez que el setup se completa
    notifyListeners();
  }

  void _listenForNewOrders() {
    debugPrint('--> Initializing Supabase Realtime listener for orders...');
    _orderSubscription = _supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1)
        .listen((List<Map<String, dynamic>> data) {
          debugPrint('--> Supabase Realtime - Data received: $data');
          if (data.isNotEmpty) {
            final newOrderData = data.first;
            final Order newOrder = Order.fromJson(newOrderData);

            // Solo actualiza y notifica si es una nueva orden o si el estado cambia de una forma que queramos
            if (_currentNewOrder == null || _currentNewOrder!.id != newOrder.id) {
              _currentNewOrder = newOrder; // Establece el nuevo pedido
              notifyListeners(); // Notifica a los listeners (HomeScreen) para que se redibujen

              // Dispara la notificación del sistema (banner)
              notificationService.showNotification(
                id: 0, // Un ID único para la notificación
                title: '¡Nuevo Pedido Recibido!',
                body: 'Pedido para ${newOrder.customerName} a ${newOrder.customerAddress}. Total: \$${newOrder.totalAmount.toStringAsFixed(2)}',
                payload: newOrder.id,
              );
              debugPrint('Notification triggered for order: ${newOrder.id}');
            } else {
              debugPrint('--> Duplicate order ID received, skipping UI update and system notification: ${newOrder.id}');
            }
          } else {
            // Si el stream devuelve una lista vacía (ej. ya no hay pedidos pendientes)
            // y actualmente hay un pedido mostrado, lo limpiamos de la UI.
            if (_currentNewOrder != null) {
              _currentNewOrder = null;
              notifyListeners();
              debugPrint('--> No pending orders currently matching filter. Clearing current order from UI.');
            } else {
              debugPrint('--> Supabase Realtime - No pending orders currently matching filter (UI already clear).');
            }
          }
        }, onError: (error) {
          _errorMessage = 'Error en Realtime de Supabase: $error';
          debugPrint('--> Supabase Realtime - ERROR: $error');
          _isLoading = false;
          notifyListeners();
        }, onDone: () {
          debugPrint('--> Supabase Realtime - Stream finished.');
        });
  }

  // Método para limpiar el pedido actual de la UI después de ser aceptado/declinado
  Future<void> clearCurrentNewOrder() async {
    _currentNewOrder = null;
    notifyListeners();
  }

  // Método para actualizar el estado del pedido en Supabase
  // DEBES IMPLEMENTAR ESTO EN TU REPOSITORIO DE ÓRDENES O AQUÍ SI LO MANEJAS DIRECTO
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabaseClient
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      debugPrint('Order $orderId status updated to $newStatus in Supabase.');
      // Importante: Si actualizas el estado a algo que no sea 'pending',
      // el listener de Realtime lo detectará y el pedido desaparecerá
      // automáticamente de currentNewOrder si el filtro lo excluye.
    } catch (e) {
      debugPrint('Error updating order status in Supabase: $e');
      _errorMessage = 'No se pudo actualizar el estado del pedido: $e';
      notifyListeners();
    }
  }


  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}