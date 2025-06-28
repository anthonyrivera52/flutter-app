// lib/viewmodel/active_order_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
// import 'package:delivery_app_mvvm/service/mock_location_service.dart'; // Remove this import as it's provided externally
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart'; // Import HomeViewModel if needed for auth state

class ActiveOrderViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  final LocationService _locationService; // This will now be injected
  final BuildContext _context; // Consider if BuildContext is truly needed here or if an event callback is better.

  // New: List of all assigned orders for this driver
  List<Order> _assignedOrders = [];
  List<Order> get assignedOrders => _assignedOrders;

  Order? _activeOrder; // The specific order the driver is currently viewing/processing
  bool _isLoading = false;
  String? _errorMessage;

  List<bool> _itemChecked = [];
  List<bool> get itemChecked => _itemChecked;

  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _assignedOrdersSubscription; // Stream for assigned orders

  Order? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Modify the constructor to accept LocationService
  ActiveOrderViewModel(this._supabaseClient, this._context, {
    required LocationService locationService, // Make it a required named parameter
  }) : _locationService = locationService { // Initialize _locationService from the parameter
    _startListeningToLocation();
    _startListeningToAssignedOrders(); // Start listening for assigned orders
  }

  // --- Location Tracking ---
  void _startListeningToLocation() {
    _locationSubscription = _locationService.getLocationStream().listen(
      (location) {
        _currentDriverLocation = location;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error en el stream de ubicación: $error';
        notifyListeners();
        debugPrint('ActiveOrderViewModel Location Stream Error: $error');
      },
    );
  }

  LocationData? _currentDriverLocation;
  LocationData? get currentDriverLocation => _currentDriverLocation;
  void updateDriverLocation(LocationData newLocation) {
    _currentDriverLocation = newLocation;
    notifyListeners();
  }


  // --- Assigned Orders Management ---
  void _startListeningToAssignedOrders() {
    _assignedOrdersSubscription?.cancel(); // Cancel any existing subscription

    // Get current user ID (assuming user is logged in via Supabase Auth)
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('ActiveOrderViewModel: User not authenticated, cannot listen for assigned orders.');
      _assignedOrders = []; // Clear any old data
      notifyListeners();
      return;
    }

    // Listen to orders assigned to this user
    // We remove the .in_() here and filter the received data in Dart.
    _assignedOrdersSubscription = _supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId) // Filter by the current driver's ID
        .listen((data) {
          debugPrint('ActiveOrderViewModel: Received assigned orders data: $data');

          // Filter the orders based on their status in Dart
          final List<String> activeStatuses = [
            'accepted',
            'arrived_at_restaurant',
            'picking_up',
            'picked_up',
            'delivering'
          ];

          _assignedOrders = data
              .map((map) => Order.fromJson(map))
              .where((order) => activeStatuses.contains(order.status))
              .toList();

          notifyListeners();

          // Optionally, if the current active order is no longer in the assigned list, clear it.
          if (_activeOrder != null && !_assignedOrders.any((order) => order.id == _activeOrder!.id)) {
            _activeOrder = null;
            notifyListeners();
          }
        }, onError: (error) {
          _errorMessage = 'Error listening to assigned orders: $error';
          debugPrint('ActiveOrderViewModel: Assigned Orders Stream Error: $error');
          notifyListeners();
        });
  }

  // Method to set a specific order as the actively viewed/processed order
  void setActiveOrder(Order order) {
    _activeOrder = order;
    if (order.items != null && order.items!.isNotEmpty) {
      _itemChecked = List<bool>.filled(order.items!.length, false);
    } else {
      _itemChecked = [];
    }
    notifyListeners();
  }

  // Method to update a single item's checked state
  void setItemChecked(int index, bool value) {
    if (index >= 0 && index < _itemChecked.length) {
      _itemChecked[index] = value;
      notifyListeners();
    }
  }

  // --- Order Status Updates ---
  Future<void> updateOrderStatus(String newStatus) async {
    if (_activeOrder == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseClient
          .from('orders')
          .update({'status': newStatus})
          .eq('id', _activeOrder!.id);

      debugPrint('Order ${_activeOrder!.id} status updated to $newStatus in Supabase.');

      // The stream listener will automatically update _activeOrder when Supabase data changes.
      // So no need to manually call _activeOrder!.copyWith(status: newStatus) here.
    } catch (e) {
      _errorMessage = 'Error al actualizar estado: $e';
      debugPrint('Error updating order status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeActiveOrder() async {
    // This is called when an order is truly finished (e.g., status is 'delivered')
    _activeOrder = null;
    notifyListeners();
    // The stream will eventually remove it from _assignedOrders as well
  }

  // Use this if you need to manually "clear" the active order from view (e.g., driver rejects)
  Future<void> clearActiveOrderAndSetStatus(String newStatus) async {
    if (_activeOrder == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseClient
          .from('orders')
          .update({'status': newStatus})
          .eq('id', _activeOrder!.id);
      _activeOrder = null; // Clear active order locally immediately
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error clearing active order: $e';
      debugPrint('Error clearing active order: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  @override
  void dispose() {
    debugPrint('ActiveOrderViewModel DISPOSING...');
    _locationSubscription?.cancel();
    _assignedOrdersSubscription?.cancel(); // Cancel assigned orders stream
    super.dispose();
  }
}