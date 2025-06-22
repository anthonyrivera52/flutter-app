import 'dart:async';
import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/order_service.dart';
import 'package:delivery_app_mvvm/service/mock_order_service.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:delivery_app_mvvm/service/mock_location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // Import provider to access other view models
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart'; // Import HomeViewModel

class ActiveOrderViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  final OrderService _orderService = MockOrderService();
  final LocationService _locationService = MockLocationService();

  Order? _activeOrder;
  bool _isLoading = false;
  String? _errorMessage;
  LocationData? _currentDriverLocation;

  List<bool> _itemChecked = []; // New property for item checks
  List<bool> get itemChecked => _itemChecked;

  StreamSubscription<LocationData>? _locationSubscription;

  Order? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LocationData? get currentDriverLocation => _currentDriverLocation;

  // Add BuildContext to the constructor to allow accessing HomeViewModel
  final BuildContext _context; // Store context

  ActiveOrderViewModel(this._supabaseClient, this._context) {
    _startListeningToLocation();
  }

  void _startListeningToLocation() {
    _locationSubscription = _locationService.getLocationStream().listen(
      (location) {
        _currentDriverLocation = location;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error en el stream de ubicación: $error';
        notifyListeners();
      },
    );
  }

  void setActiveOrder(Order order) {
    _activeOrder = order;
    if (_activeOrder != null && _activeOrder!.items != null) {
      initializeItemChecked(_activeOrder!.items!.length);
    } else {
      _itemChecked = []; // Clear if no active order or no items
    }
    notifyListeners();
  }
  
  // Method to initialize item checked state when an order is set
  void initializeItemChecked(int itemCount) {
    _itemChecked = List<bool>.filled(itemCount, false);
    notifyListeners();
  }

    // Method to update a single item's checked state
  void setItemChecked(int index, bool value) {
    if (index >= 0 && index < _itemChecked.length) {
      _itemChecked[index] = value;
      notifyListeners();
    }
  }


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

      debugPrint('Order $_activeOrder status updated to $newStatus in Supabase.');

      _activeOrder = _activeOrder!.copyWith(status: newStatus);

    } catch (e) {
      _errorMessage = 'Error al actualizar estado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void>  completeActiveOrder() async {
    _activeOrder = null;
    notifyListeners();
  }

  Future<void> clearActiveOrder(String newStatus) async {
    _activeOrder = null;
    await _supabaseClient
      .from('orders')
      .update({'status': newStatus})
      .eq('id', _activeOrder!.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    (_locationService as MockLocationService).dispose();
    super.dispose();
  }
}