// lib/viewmodel/new_order_viewmodel.dart

import 'dart:async';
import 'dart:math';

import 'package:delivery_app_mvvm/core/utils/constants.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewOrderViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _orderSubscription;
  final NotificationService notificationService;
  final LocationService? _locationService;
  StreamSubscription? _locationSubscription;

  // Radio máximo para recibir pedidos (en km) - configurable
  double maxRadiusKm;

  Order? _currentNewOrder;
  Order? get currentNewOrder => _currentNewOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Distancia al restaurante del pedido actual
  double? _distanceToRestaurant;
  double? get distanceToRestaurant => _distanceToRestaurant;

  // Ubicación actual del repartidor (se actualiza desde HomeViewModel)
  double? _currentLat;
  double? _currentLon;

  // Constructor
  NewOrderViewModel(
    this._supabaseClient,
    this.notificationService, {
    this.maxRadiusKm = 5.0, // Default: 5km - se sobrescribe con AppConstants.maxRadius
    LocationService? locationService,
  })  : _locationService = locationService {
    // Usar el radio configurado según el entorno
    maxRadiusKm = AppConstants.maxRadius;

    _listenForNewOrders();

    // Escuchar cambios de ubicación si se proporciona el servicio
    if (_locationService != null) {
      _locationSubscription = _locationService!.getLocationStream().listen(
        (location) {
          updateCurrentLocation(location.latitude, location.longitude);
        },
        onError: (error) {
          debugPrint('Location stream error in NewOrderViewModel: $error');
        },
      );
    }
  }

  /// Actualizar la ubicación actual del repartidor
  void updateCurrentLocation(double lat, double lon) {
    _currentLat = lat;
    _currentLon = lon;
  }

  /// Método para iniciar la escucha de nuevos pedidos
  void _listenForNewOrders() {
    _orderSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Usar la tabla configurada en constants (puede ser 'sales' o 'orders')
    final tableName = AppConstants.ordersTable;

    debugPrint('--> Initializing Supabase Realtime listener for table: $tableName');

    _orderSubscription = _supabaseClient
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('status', AppConstants.statusPending)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((List<Map<String, dynamic>> data) {
          _isLoading = false;
          _errorMessage = null;

          debugPrint('--> Supabase Realtime - Data received: $data');

          if (data.isNotEmpty) {
            final newOrderData = data.first;
            final Order newOrder = Order.fromJson(newOrderData);

            // Verificar si es un pedido genuinamente nuevo
            if (_currentNewOrder == null || _currentNewOrder!.id != newOrder.id) {
              // Verificar geofencing si tenemos ubicación actual
              if (_currentLat != null && _currentLon != null) {
                _checkOrderWithGeofencing(newOrder);
              } else {
                // Sin ubicación, mostrar el pedido
                _currentNewOrder = newOrder;
                _distanceToRestaurant = null;
                notifyListeners();
                _showNotification(newOrder, null);
              }
            } else {
              debugPrint('--> Duplicate order ID received, skipping: ${newOrder.id}');
            }
          } else {
            if (_currentNewOrder != null) {
              _currentNewOrder = null;
              _distanceToRestaurant = null;
              notifyListeners();
              debugPrint('--> No pending orders. Clearing current order from UI.');
            } else {
              debugPrint('--> Supabase Realtime - No pending orders.');
            }
          }
        }, onError: (error) {
          _isLoading = false;
          _errorMessage = 'Error en Realtime de Supabase: $error';
          debugPrint('--> Supabase Realtime - ERROR: $error');
          notifyListeners();
        }, onDone: () {
          debugPrint('--> Supabase Realtime - Stream finished unexpectedly.');
        });
  }

  /// Verificar el pedido contra el geofencing
  void _checkOrderWithGeofencing(Order newOrder) {
    final restaurantLat = newOrder.restaurantLocation.latitude;
    final restaurantLon = newOrder.restaurantLocation.longitude;

    // Calcular distancia al restaurante
    final distance = calculateDistance(
      _currentLat!,
      _currentLon!,
      restaurantLat,
      restaurantLon,
    );

    _distanceToRestaurant = distance;

    debugPrint('--> Distance to restaurant (${newOrder.restaurantName}): ${distance.toStringAsFixed(2)}km');

    // Verificar si está dentro del radio
    if (distance <= maxRadiusKm) {
      // Dentro del radio - mostrar pedido
      _currentNewOrder = newOrder;
      notifyListeners();
      _showNotification(newOrder, distance);
      debugPrint('--> Order within radius ($maxRadiusKm km). Showing to driver.');
    } else {
      // Fuera del radio - no mostrar
      debugPrint('--> Order outside radius ($maxRadiusKm km). Ignoring.');
      _currentNewOrder = null;
      _distanceToRestaurant = null;
      // No notifyListeners() aquí para no molestar al usuario con pedidos que no le interesan
    }
  }

  /// Calcular distancia usando fórmula de Haversine
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Mostrar notificación del sistema
  void _showNotification(Order order, double? distanceKm) {
    String body;
    if (distanceKm != null) {
      body = '${order.restaurantName} - ${distanceKm.toStringAsFixed(1)}km de distancia. '
          'Total: \$${order.totalAmount.toStringAsFixed(2)}';
    } else {
      body = 'Pedido para ${order.customerName} a ${order.customerAddress}. '
          'Total: \$${order.totalAmount.toStringAsFixed(2)}';
    }

    notificationService.showNotification(
      id: AppConstants.newOrderNotificationId,
      title: distanceKm != null ? '¡Nuevo Pedido Cercano!' : '¡Nuevo Pedido Recibido!',
      body: body,
      payload: order.id,
    );
    debugPrint('Notification triggered for order: ${order.id}');
  }

  /// Método para reintentar obtener/re-establecer el listener
  Future<void> fetchNewOrder() async {
    if (!_isLoading) {
      debugPrint('--> Manually attempting to fetch/re-establish new order listener.');
      _listenForNewOrders();
    }
  }

  /// Limpiar el pedido actual mostrado
  void clearCurrentNewOrder() {
    if (_currentNewOrder != null) {
      _currentNewOrder = null;
      _distanceToRestaurant = null;
      notifyListeners();
      debugPrint('--> Current new order cleared from ViewModel UI.');
    }
  }

  /// Actualizar estado del pedido en Supabase
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tableName = AppConstants.ordersTable;
      await _supabaseClient
          .from(tableName)
          .update({'status': newStatus})
          .eq('id', orderId);
      debugPrint('Order $orderId status updated to $newStatus in Supabase.');
    } catch (e) {
      debugPrint('Error updating order status in Supabase: $e');
      _errorMessage = 'No se pudo actualizar el estado del pedido: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Asignar repartidor al pedido
  Future<void> assignDriver(String orderId, String driverId) async {
    try {
      final tableName = AppConstants.ordersTable;
      await _supabaseClient
          .from(tableName)
          .update({
            'driver_id': driverId,
            'status': AppConstants.statusAccepted,
          })
          .eq('id', orderId);
      debugPrint('Driver $driverId assigned to order $orderId');
    } catch (e) {
      debugPrint('Error assigning driver to order: $e');
      _errorMessage = 'No se pudo asignar el repartidor: $e';
    }
  }

  /// Aceptar un pedido
  Future<void> acceptOrder(String orderId) async {
    debugPrint('Attempting to accept order: $orderId');

    // Obtener el ID del usuario actual
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      // Asignar el repartidor al pedido
      await assignDriver(orderId, userId);
    }

    await updateOrderStatus(orderId, AppConstants.statusAccepted);
    clearCurrentNewOrder();
  }

  /// Rechazar un pedido
  Future<void> rejectOrder(String orderId) async {
    debugPrint('Attempting to reject order: $orderId');
    await updateOrderStatus(orderId, AppConstants.statusRejected);
    clearCurrentNewOrder();
  }

  /// Cambiar el radio máximo de geofencing
  void setMaxRadius(double radiusKm) {
    maxRadiusKm = radiusKm;
    debugPrint('--> Max radius updated to: $radiusKm km');
  }

  @override
  void dispose() {
    debugPrint('--> NewOrderViewModel DISPOSED: Canceling order subscription.');
    _orderSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
