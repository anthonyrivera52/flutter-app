// lib/core/providers/delivery_provider.dart
// Provider unificado para Delivery Orders - usa tabla sales + delivery_orders

import 'dart:async';

import 'package:delivery_app_mvvm/core/utils/constants.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'location_providers.dart';

// ============================================================================
// PROVIDERS BÁSICOS
// ============================================================================

final deliverySupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final deliveryNotificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ============================================================================
// MODELO: DELIVERY ORDER
// ============================================================================

class DeliveryOrder {
  final String id;
  final String? saleId;
  final String? driverId;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final LatLng customerLocation;
  final String? restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final LatLng restaurantLocation;
  final String status;
  final double estimatedEarnings;
  final int estimatedTimeMinutes;
  final double distanceKm;
  final String? pickupCode;
  final String? deliveryCode;
  final LatLng? currentLocation;
  final double totalAmount;
  final DateTime createdAt;

  DeliveryOrder({
    required this.id,
    this.saleId,
    this.driverId,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerLocation,
    this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantLocation,
    required this.status,
    required this.estimatedEarnings,
    required this.estimatedTimeMinutes,
    required this.distanceKm,
    this.pickupCode,
    this.deliveryCode,
    this.currentLocation,
    required this.totalAmount,
    required this.createdAt,
  });

  factory DeliveryOrder.fromSaleJson(Map<String, dynamic> saleJson, Map<String, dynamic>? deliveryData) {
    final deliveryMetadata = saleJson['delivery_metadata'] as Map<String, dynamic>? ?? {};
    final shippingAddress = saleJson['shipping_address'] as Map<String, dynamic>? ?? {};

    double customerLat = (deliveryMetadata['customer_latitude'] as num?)?.toDouble() ??
        (shippingAddress['latitude'] as num?)?.toDouble() ?? 0.0;
    double customerLng = (deliveryMetadata['customer_longitude'] as num?)?.toDouble() ??
        (shippingAddress['longitude'] as num?)?.toDouble() ?? 0.0;

    String restaurantName = deliveryMetadata['restaurant_name'] as String? ??
        saleJson['store_name'] as String? ?? 'Restaurante';
    String restaurantAddress = deliveryMetadata['restaurant_address'] as String? ?? '';

    double restaurantLat = (deliveryMetadata['restaurant_latitude'] as num?)?.toDouble() ?? 0.0;
    double restaurantLng = (deliveryMetadata['restaurant_longitude'] as num?)?.toDouble() ?? 0.0;

    double tip = (saleJson['tip'] as num?)?.toDouble() ?? 0.0;
    double deliveryFee = (deliveryMetadata['delivery_fee'] as num?)?.toDouble() ??
        (saleJson['shipping_amount'] as num?)?.toDouble() ?? 2.0;
    double estimatedEarnings = tip + deliveryFee;

    double distanceKm = 0.0;
    if (restaurantLat != 0.0 && restaurantLng != 0.0 && customerLat != 0.0 && customerLng != 0.0) {
      distanceKm = calculateDistance(restaurantLat, restaurantLng, customerLat, customerLng);
    }

    int estimatedTime = (distanceKm * 2 + 5).round();
    double totalAmount = (saleJson['grand_total'] as num?)?.toDouble() ??
        (saleJson['total_amount'] as num?)?.toDouble() ?? 0.0;

    return DeliveryOrder(
      id: saleJson['id'] as String,
      saleId: saleJson['id'] as String,
      driverId: deliveryData?['driver_id'] as String?,
      customerId: deliveryData?['customer_id'] as String?,
      customerName: deliveryData?['customer_name'] as String? ??
          shippingAddress['name'] as String? ?? 'Cliente',
      customerPhone: deliveryData?['customer_phone'] as String? ??
          shippingAddress['phone'] as String? ?? '',
      customerAddress: deliveryData?['customer_address'] as String? ??
          shippingAddress['address'] as String? ?? shippingAddress['street'] as String? ?? '',
      customerLocation: LatLng(customerLat, customerLng),
      restaurantId: deliveryData?['restaurant_id'] as String?,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantLocation: LatLng(restaurantLat, restaurantLng),
      status: deliveryData?['status'] as String? ?? _mapSaleStatusToDeliveryStatus(saleJson['status'] as String?),
      estimatedEarnings: estimatedEarnings,
      estimatedTimeMinutes: estimatedTime,
      distanceKm: distanceKm,
      pickupCode: deliveryData?['pickup_code'] as String? ??
          saleJson['verification_code'] as String?,
      deliveryCode: deliveryData?['delivery_code'] as String?,
      currentLocation: null,
      totalAmount: totalAmount,
      createdAt: DateTime.parse(saleJson['created_at'] as String),
    );
  }

  static String _mapSaleStatusToDeliveryStatus(String? saleStatus) {
    switch (saleStatus?.toUpperCase()) {
      case 'NEW':
      case 'PENDING':
      case 'CONFIRMED':
        return AppConstants.deliveryStatusPending;
      case 'PREPARING':
        return AppConstants.deliveryStatusAccepted;
      case 'READY':
        return AppConstants.deliveryStatusPickedUp;
      case 'DELIVERED':
        return AppConstants.deliveryStatusDelivered;
      case 'CANCELLED':
        return AppConstants.deliveryStatusCancelled;
      default:
        return AppConstants.deliveryStatusPending;
    }
  }

  DeliveryOrder copyWith({
    String? id, String? saleId, String? driverId, String? customerId,
    String? customerName, String? customerPhone, String? customerAddress,
    LatLng? customerLocation, String? restaurantId, String? restaurantName,
    String? restaurantAddress, LatLng? restaurantLocation, String? status,
    double? estimatedEarnings, int? estimatedTimeMinutes, double? distanceKm,
    String? pickupCode, String? deliveryCode, LatLng? currentLocation,
    double? totalAmount, DateTime? createdAt,
  }) {
    return DeliveryOrder(
      id: id ?? this.id, saleId: saleId ?? this.saleId,
      driverId: driverId ?? this.driverId, customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLocation: customerLocation ?? this.customerLocation,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      status: status ?? this.status,
      estimatedEarnings: estimatedEarnings ?? this.estimatedEarnings,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      pickupCode: pickupCode ?? this.pickupCode,
      deliveryCode: deliveryCode ?? this.deliveryCode,
      currentLocation: currentLocation ?? this.currentLocation,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ============================================================================
// ESTADOS
// ============================================================================

class NewDeliveryOrderState {
  final DeliveryOrder? currentNewOrder;
  final bool isLoading;
  final String? errorMessage;
  final double? distanceToRestaurant;
  final bool isWithinRadius;

  const NewDeliveryOrderState({
    this.currentNewOrder, this.isLoading = false, this.errorMessage,
    this.distanceToRestaurant, this.isWithinRadius = false,
  });

  NewDeliveryOrderState copyWith({
    DeliveryOrder? currentNewOrder, bool? isLoading, String? errorMessage,
    double? distanceToRestaurant, bool? isWithinRadius, bool clearOrder = false,
  }) {
    return NewDeliveryOrderState(
      currentNewOrder: clearOrder ? null : (currentNewOrder ?? this.currentNewOrder),
      isLoading: isLoading ?? this.isLoading, errorMessage: errorMessage,
      distanceToRestaurant: clearOrder ? null : (distanceToRestaurant ?? this.distanceToRestaurant),
      isWithinRadius: clearOrder ? false : (isWithinRadius ?? this.isWithinRadius),
    );
  }
}

class ActiveDeliveryState {
  final List<DeliveryOrder> assignedOrders;
  final DeliveryOrder? activeOrder;
  final bool isLoading;
  final String? errorMessage;
  final double? distanceToRestaurant;
  final double? distanceToCustomer;

  const ActiveDeliveryState({
    this.assignedOrders = const [], this.activeOrder, this.isLoading = false,
    this.errorMessage, this.distanceToRestaurant, this.distanceToCustomer,
  });

  ActiveDeliveryState copyWith({
    List<DeliveryOrder>? assignedOrders, DeliveryOrder? activeOrder, bool? isLoading,
    String? errorMessage, double? distanceToRestaurant, double? distanceToCustomer,
    bool clearActiveOrder = false,
  }) {
    return ActiveDeliveryState(
      assignedOrders: assignedOrders ?? this.assignedOrders,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      isLoading: isLoading ?? this.isLoading, errorMessage: errorMessage,
      distanceToRestaurant: clearActiveOrder ? null : (distanceToRestaurant ?? this.distanceToRestaurant),
      distanceToCustomer: clearActiveOrder ? null : (distanceToCustomer ?? this.distanceToCustomer),
    );
  }
}

// ============================================================================
// NOTIFIERS
// ============================================================================

class NewDeliveryOrderNotifier extends StateNotifier<NewDeliveryOrderState> {
  final SupabaseClient _supabaseClient;
  final NotificationService _notificationService;
  final Ref _ref;
  StreamSubscription? _saleSubscription;
  LocationData? _currentLocation;

  NewDeliveryOrderNotifier(this._supabaseClient, this._notificationService, this._ref)
      : super(const NewDeliveryOrderState()) {
    _init();
  }

  void _init() {
    _listenForNewSales();
    _ref.listen(locationStreamProvider, (previous, next) {
      next.whenData((location) {
        _currentLocation = location;
        if (state.currentNewOrder != null) _checkGeofencing(state.currentNewOrder!);
      });
    });
  }

  void _listenForNewSales() {
    _saleSubscription?.cancel();
    state = state.copyWith(isLoading: true, errorMessage: null);

    final query = _supabaseClient.from('sales').stream(primaryKey: ['id'])
        .eq('order_type', 'DELIVERY')
        .order('created_at', ascending: false).limit(10);

    _saleSubscription = query.listen(
      (List<Map<String, dynamic>> data) async {
        state = state.copyWith(isLoading: false);
        final pendingData = data.where((item) =>
          AppConstants.saleStatusesPending.contains(item['status'] as String?)
        ).toList();
        if (pendingData.isNotEmpty) {
          final saleData = pendingData.first;
          final deliveryData = await _getDeliveryOrderData(saleData['id'] as String);
          final newOrder = DeliveryOrder.fromSaleJson(saleData, deliveryData);
          if (state.currentNewOrder == null || state.currentNewOrder!.id != newOrder.id) {
            _checkGeofencing(newOrder);
          }
        } else {
          if (state.currentNewOrder != null) state = state.copyWith(clearOrder: true);
        }
      },
      onError: (error) => state = state.copyWith(isLoading: false, errorMessage: 'Error: $error'),
    );
  }

  Future<Map<String, dynamic>?> _getDeliveryOrderData(String saleId) async {
    try {
      return await _supabaseClient.from('delivery_orders').select()
          .eq('sale_id', saleId).maybeSingle();
    } catch (e) { return null; }
  }

  void _checkGeofencing(DeliveryOrder newOrder) {
    if (_currentLocation == null) {
      state = state.copyWith(currentNewOrder: newOrder, isWithinRadius: false);
      return;
    }
    final maxRadius = _ref.read(maxGeofenceRadiusProvider);
    final distance = calculateDistance(_currentLocation!.latitude, _currentLocation!.longitude,
        newOrder.restaurantLocation.latitude, newOrder.restaurantLocation.longitude);
    final isWithin = distance <= maxRadius;
    state = state.copyWith(currentNewOrder: newOrder, distanceToRestaurant: distance, isWithinRadius: isWithin);
    if (isWithin) {
      _notificationService.showNotification(
        id: AppConstants.newOrderNotificationId,
        title: '¡Nuevo Pedido Cercano!',
        body: '${newOrder.restaurantName} - ${distance.toStringAsFixed(1)}km. Ganancia: \$${newOrder.estimatedEarnings.toStringAsFixed(2)}',
        payload: newOrder.id,
      );
    }
  }

  Future<bool> acceptOrder(String saleId) async {
    state = state.copyWith(isLoading: true);
    try {
      final driverId = _supabaseClient.auth.currentUser?.id;
      if (driverId == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Usuario no autenticado');
        return false;
      }
      final pickupCode = AppConstants.isDevelopment ? AppConstants.devPickupCode : _generateRandomCode(4);
      final deliveryCode = AppConstants.isDevelopment ? AppConstants.devDeliveryCode : _generateRandomCode(4);
      await _supabaseClient.from('delivery_orders').insert({
        'sale_id': saleId, 'driver_id': driverId, 'status': AppConstants.deliveryStatusAccepted,
        'pickup_code': pickupCode, 'delivery_code': deliveryCode,
        'current_latitude': _currentLocation?.latitude, 'current_longitude': _currentLocation?.longitude,
      });
      state = state.copyWith(clearOrder: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al aceptar: $e');
      return false;
    }
  }

  void rejectOrder(String saleId) { state = state.copyWith(clearOrder: true); }
  void clearCurrentNewOrder() { state = state.copyWith(clearOrder: true); }

  String _generateRandomCode(int length) {
    return (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(length, '0');
  }

  @override void dispose() { _saleSubscription?.cancel(); super.dispose(); }
}

final newDeliveryOrderProvider = StateNotifierProvider<NewDeliveryOrderNotifier, NewDeliveryOrderState>((ref) {
  return NewDeliveryOrderNotifier(ref.watch(deliverySupabaseClientProvider),
      ref.watch(deliveryNotificationServiceProvider), ref);
});

// ============================================================================
// ACTIVE DELIVERY NOTIFIER
// ============================================================================

class ActiveDeliveryNotifier extends StateNotifier<ActiveDeliveryState> {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _deliverySubscription;

  ActiveDeliveryNotifier(this._supabaseClient) : super(const ActiveDeliveryState()) {
    _startListeningToAssignedOrders();
  }

  void _startListeningToAssignedOrders() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    final query = _supabaseClient.from('delivery_orders').stream(primaryKey: ['id'])
        .eq('driver_id', userId).order('created_at', ascending: false);

    _deliverySubscription = query.listen(
      (List<Map<String, dynamic>> data) async {
        final activeData = data.where((item) =>
          AppConstants.activeDeliveryStatuses.contains(item['status'] as String?)
        ).toList();
        final orders = <DeliveryOrder>[];
        for (final deliveryData in activeData) {
          final saleData = await _getSaleData(deliveryData['sale_id'] as String);
          if (saleData != null) orders.add(DeliveryOrder.fromSaleJson(saleData, deliveryData));
        }
        state = state.copyWith(assignedOrders: orders);
        if (state.activeOrder != null && !orders.any((o) => o.id == state.activeOrder!.id)) {
          state = state.copyWith(clearActiveOrder: true);
        }
      },
      onError: (error) => state = state.copyWith(errorMessage: 'Error: $error'),
    );
  }

  Future<Map<String, dynamic>?> _getSaleData(String saleId) async {
    try {
      return await _supabaseClient.from('sales').select().eq('id', saleId).maybeSingle();
    } catch (e) { return null; }
  }

  void setActiveOrder(DeliveryOrder order) { state = state.copyWith(activeOrder: order); }

  Future<void> updateDeliveryStatus(String newStatus) async {
    if (state.activeOrder == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _supabaseClient.from('delivery_orders').update({
        'status': newStatus, 'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', state.activeOrder!.id);
      final saleId = state.activeOrder!.saleId;
      final saleStatus = _mapDeliveryStatusToSaleStatus(newStatus);
      if (saleStatus != null && saleId != null) {
        await _supabaseClient.from('sales').update({'status': saleStatus}).eq('id', saleId);
      }
      state = state.copyWith(isLoading: false);
      if (newStatus == AppConstants.deliveryStatusDelivered) {
        state = state.copyWith(clearActiveOrder: true);
      }
    } catch (e) { state = state.copyWith(isLoading: false, errorMessage: 'Error: $e'); }
  }

  String? _mapDeliveryStatusToSaleStatus(String deliveryStatus) {
    switch (deliveryStatus) {
      case 'accepted': return 'ACCEPTED';
      case 'picking_up': return 'PREPARING';
      case 'picked_up': return 'READY';
      case 'delivering': return 'DELIVERING';
      case 'delivered': return 'DELIVERED';
      case 'cancelled': return 'CANCELLED';
      default: return null;
    }
  }

  @override void dispose() { _deliverySubscription?.cancel(); super.dispose(); }
}

final activeDeliveryProvider = StateNotifierProvider<ActiveDeliveryNotifier, ActiveDeliveryState>((ref) {
  return ActiveDeliveryNotifier(ref.watch(deliverySupabaseClientProvider));
});

// ============================================================================
// HISTORIAL DE PEDIDOS
// ============================================================================

final deliveryHistoryProvider = FutureProvider.family<List<DeliveryOrder>, DateTime>((ref, startDate) async {
  final supabaseClient = ref.watch(deliverySupabaseClientProvider);
  final userId = supabaseClient.auth.currentUser?.id;
  if (userId == null) return [];
  final result = await supabaseClient.from('delivery_orders').select()
      .eq('driver_id', userId).eq('status', AppConstants.deliveryStatusDelivered)
      .gte('created_at', startDate.toIso8601String()).order('created_at', ascending: false);
  return result.map((data) => DeliveryOrder.fromSaleJson(
    {'id': data['sale_id'], 'created_at': data['created_at']}, data)).toList();
});

final totalEarningsProvider = FutureProvider.family<double, DateTime>((ref, startDate) async {
  final supabaseClient = ref.watch(deliverySupabaseClientProvider);
  final userId = supabaseClient.auth.currentUser?.id;
  if (userId == null) return 0.0;
  final result = await supabaseClient.from('delivery_orders').select('estimated_earnings')
      .eq('driver_id', userId).eq('status', AppConstants.deliveryStatusDelivered)
      .gte('created_at', startDate.toIso8601String());
  double total = 0.0;
  for (final item in result) {
    total += ((item['estimated_earnings'] as num?)?.toDouble() ?? 0.0);
  }
  return total;
});
