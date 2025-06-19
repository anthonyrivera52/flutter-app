// lib/viewmodel/new_order_viewmodel.dart

import 'dart:async';

import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewOrderViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _orderSubscription; // Manages the Realtime stream connection
  final NotificationService notificationService;

  Order? _currentNewOrder;
  Order? get currentNewOrder => _currentNewOrder;

  bool _isLoading = false; // Indicates if data is being loaded or stream is initializing
  bool get isLoading => _isLoading;

  String? _errorMessage; // Stores any error messages
  String? get errorMessage => _errorMessage;

  // Constructor: This is where the stream should ideally start listening.
  NewOrderViewModel(this._supabaseClient, this.notificationService) {
    _listenForNewOrders(); // Start listening as soon as the ViewModel is created.
  }

  // This method is for initiating or re-initiating the stream,
  // typically called once at ViewModel creation or to recover from an error.
  void _listenForNewOrders() {
    // If a subscription already exists, cancel it to avoid multiple listeners.
    // This is useful if _listenForNewOrders is called again (e.g., after an error).
    _orderSubscription?.cancel();

    _isLoading = true; // Set loading state while stream connects
    _errorMessage = null; // Clear previous errors
    notifyListeners(); // Notify UI about loading state

    debugPrint('--> Initializing Supabase Realtime listener for orders...');

    _orderSubscription = _supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1)
        .listen((List<Map<String, dynamic>> data) {
          _isLoading = false; // Data received, stop loading
          _errorMessage = null; // Clear any previous error on successful data

          debugPrint('--> Supabase Realtime - Data received: $data');

          if (data.isNotEmpty) {
            final newOrderData = data.first;
            final Order newOrder = Order.fromJson(newOrderData);

            // Only update and notify if it's a genuinely new order ID
            // or if the previous order was cleared.
            if (_currentNewOrder == null || _currentNewOrder!.id != newOrder.id) {
              _currentNewOrder = newOrder;
              notifyListeners(); // Notify UI about the new order

              // Trigger system notification (banner)
              notificationService.showNotification(
                id: 0,
                title: '¡Nuevo Pedido Recibido!',
                body: 'Pedido para ${newOrder.customerName} a ${newOrder.customerAddress}. Total: \$${newOrder.totalAmount.toStringAsFixed(2)}',
                payload: newOrder.id,
              );
              debugPrint('Notification triggered for order: ${newOrder.id}');
            } else {
              debugPrint('--> Duplicate order ID received, skipping UI update and system notification: ${newOrder.id}');
            }
          } else {
            // If the stream sends an empty list (meaning no pending orders matching filter)
            // and we currently have an order displayed, clear it from the UI.
            if (_currentNewOrder != null) {
              _currentNewOrder = null;
              notifyListeners();
              debugPrint('--> No pending orders currently matching filter. Clearing current order from UI.');
            } else {
              debugPrint('--> Supabase Realtime - No pending orders currently matching filter (UI already clear).');
            }
          }
        }, onError: (error) {
          _isLoading = false; // Stop loading on error
          _errorMessage = 'Error en Realtime de Supabase: $error';
          debugPrint('--> Supabase Realtime - ERROR: $error');
          notifyListeners();
        }, onDone: () {
          debugPrint('--> Supabase Realtime - Stream finished (unexpectedly for a continuous listener).');
          // You might want to re-initiate the stream here if it unexpectedly closes.
          // _listenForNewOrders(); // Uncomment if you want to automatically restart the stream on completion.
        });
  }

  // This method is for a *manual fetch* or *re-attempt connection* if the stream fails,
  // not for continuous listening. It effectively re-triggers the listener.
  Future<void> fetchNewOrder() async {
    // Only re-initialize the stream if not already loading or in an error state requiring a retry
    if (!_isLoading) { // Prevents multiple rapid calls if already in progress
      debugPrint('--> Manually attempting to fetch/re-establish new order listener.');
      _listenForNewOrders(); // Re-establish the listener
    }
  }

  // Method to clear the currently displayed new order from the UI
  void clearCurrentNewOrder() {
    if (_currentNewOrder != null) {
      _currentNewOrder = null;
      notifyListeners();
      debugPrint('--> Current new order cleared from ViewModel UI.');
    }
  }

  // Method to update order status in Supabase
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Indicate that an operation is in progress

    try {
      await _supabaseClient
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      debugPrint('Order $orderId status updated to $newStatus in Supabase.');
      // The Realtime listener will automatically detect this change and remove the order from its stream if its status no longer matches 'pending'.
      // Therefore, the clearCurrentNewOrder() call in acceptOrder/rejectOrder is mostly for immediate UI feedback.
    } catch (e) {
      debugPrint('Error updating order status in Supabase: $e');
      _errorMessage = 'No se pudo actualizar el estado del pedido: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Update UI after operation
    }
  }

  // --- New Methods for Accept/Reject (as discussed previously) ---
  Future<void> acceptOrder(String orderId) async {
    debugPrint('Attempting to accept order: $orderId');
    await updateOrderStatus(orderId, 'accepted');
    // The clearCurrentNewOrder() here is good for immediate UI feedback.
    // The stream's filter will also eventually remove it.
    clearCurrentNewOrder();
  }

  Future<void> rejectOrder(String orderId) async {
    debugPrint('Attempting to reject order: $orderId');
    await updateOrderStatus(orderId, 'rejected');
    clearCurrentNewOrder();
  }

  @override
  void dispose() {
    debugPrint('--> NewOrderViewModel DISPOSED: Canceling order subscription.');
    _orderSubscription?.cancel(); // IMPORTANT: Cancel the stream when ViewModel is disposed.
    super.dispose();
  }
}

// Add these for ActiveOrderViewModel (if it also uses a stream and needs similar management)
// class ActiveOrderViewModel extends ChangeNotifier {
//   StreamSubscription? _activeOrderSubscription;
//   // ... other properties

//   ActiveOrderViewModel(this._supabaseClient) {
//     _listenForActiveOrders(); // Start listening for active orders
//   }

//   void _listenForActiveOrders() {
//     _activeOrderSubscription?.cancel();
//     _activeOrderSubscription = _supabaseClient
//         .from('orders')
//         .stream(primaryKey: ['id'])
//         .eq('status', 'accepted') // or whatever status denotes an active order for THIS driver
//         .listen((data) {
//           // Parse data, set _currentActiveOrder, notifyListeners()
//         }, onError: (error) {
//           // Handle error
//         });
//   }

//   @override
//   void dispose() {
//     _activeOrderSubscription?.cancel();
//     super.dispose();
//   }
// }