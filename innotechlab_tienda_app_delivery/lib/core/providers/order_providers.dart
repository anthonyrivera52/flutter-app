// lib/core/providers/order_providers.dart
// Providers para Orders - usa tabla sales + delivery_orders

import 'dart:async';

import 'package:delivery_app_mvvm/core/utils/constants.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/service/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'location_providers.dart';

/// Provider para el cliente de Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider para el servicio de notificaciones
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ============================================================================
// NEW ORDER NOTIFIER - CON GEOFENCING Y TABLA SALES
// ============================================================================

/// Estado del NewOrderNotifier
class NewOrderState {
  final Order? currentNewOrder;
  final bool isLoading;
  final String? errorMessage;
  final double? distanceToRestaurant; // Distancia en km

  const NewOrderState({
    this.currentNewOrder,
    this.isLoading = false,
    this.errorMessage,
    this.distanceToRestaurant,
  });

  NewOrderState copyWith({
    Order? currentNewOrder,
    bool? isLoading,
    String? errorMessage,
    double? distanceToRestaurant,
    bool clearOrder = false,
  }) {
    return NewOrderState(
      currentNewOrder: clearOrder ? null : (currentNewOrder ?? this.currentNewOrder),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      distanceToRestaurant: clearOrder ? null : (distanceToRestaurant ?? this.distanceToRestaurant),
    );
  }
}

/// Notifier para manejar nuevos pedidos con geofencing - SOPORTA AMBOS FORMATOS
class NewOrderNotifier extends StateNotifier<NewOrderState> {
  final SupabaseClient _supabaseClient;
  final NotificationService _notificationService;
  final Ref _ref;

  StreamSubscription? _orderSubscription;

  NewOrderNotifier(
    this._supabaseClient,
    this._notificationService,
    this._ref,
  ) : super(const NewOrderState()) {
    _listenForNewOrders();
  }

  void _listenForNewOrders() {
    _orderSubscription?.cancel();

    state = state.copyWith(isLoading: true, errorMessage: null);

    // Determinar qué tabla usar basándose en AppConstants
    final tableName = AppConstants.ordersTable;

    // Escuchar la tabla configurada (sales u orders)
    Stream<List<Map<String, dynamic>>> query;

    if (tableName == 'sales') {
      // Para sales, filtrar por order_type = DELIVERY y estados pendientes
      // NOTA: No se puede usar in_ en streams, filtramos después de recibir
      query = _supabaseClient
          .from('sales')
          .stream(primaryKey: ['id'])
          .eq('order_type', 'DELIVERY')
          .order('created_at', ascending: false)
          .limit(10);
    } else {
      // Para orders (legacy), filtrar por status = pending
      query = _supabaseClient
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1);
    }

    _orderSubscription = query.listen(
      (List<Map<String, dynamic>> data) {
        state = state.copyWith(isLoading: false);

        if (data.isNotEmpty) {
          final newOrderData = data.first;

          // Usar el factory que detecta automáticamente el formato
          final newOrder = Order.fromJson(newOrderData);

          // Verificar si es un pedido nuevo (diferente ID)
          if (state.currentNewOrder == null || state.currentNewOrder!.id != newOrder.id) {
            // GEOFENCING: Calcular distancia al restaurante
            _checkOrderWithGeofencing(newOrder);
          }
        } else {
          // No hay pedidos pendientes
          if (state.currentNewOrder != null) {
            state = state.copyWith(clearOrder: true);
          }
        }
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error en Realtime: $error',
        );
      },
    );
  }

  /// Verifica el pedido contra el geofencing
  void _checkOrderWithGeofencing(Order newOrder) {
    // Obtener ubicación actual del repartidor
    final locationAsync = _ref.read(locationStreamProvider);

    locationAsync.whenData((location) {
      final maxRadius = _ref.read(maxGeofenceRadiusProvider);

      // Calcular distancia al restaurante
      final distance = calculateDistance(
        location.latitude,
        location.longitude,
        newOrder.restaurantLocation.latitude,
        newOrder.restaurantLocation.longitude,
      );

      // Verificar si está dentro del radio
      if (distance <= maxRadius) {
        // Dentro del radio - mostrar pedido
        state = state.copyWith(
          currentNewOrder: newOrder,
          distanceToRestaurant: distance,
        );

        // Mostrar notificación
        _notificationService.showNotification(
          id: 0,
          title: '¡Nuevo Pedido Cercano!',
          body:
              '${newOrder.restaurantName} - ${distance.toStringAsFixed(1)}km de distancia. Total: \$${newOrder.totalAmount.toStringAsFixed(2)}',
          payload: newOrder.id,
        );
      } else {
        // Fuera del radio - no mostrar
        state = state.copyWith(clearOrder: true);
      }
    });
  }

  /// Aceptar un pedido
  Future<void> acceptOrder(String orderId) async {
    state = state.copyWith(isLoading: true);
    try {
      final tableName = AppConstants.ordersTable;

      if (tableName == 'sales') {
        // Para sales, actualizar el estado
        await _supabaseClient
            .from('sales')
            .update({'status': 'ACCEPTED'})
            .eq('id', orderId);
      } else {
        // Para legacy orders
        await _supabaseClient
            .from('orders')
            .update({'status': 'accepted'})
            .eq('id', orderId);
      }
      state = state.copyWith(clearOrder: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al aceptar: $e',
      );
    }
  }

  /// Rechazar un pedido
  Future<void> rejectOrder(String orderId) async {
    state = state.copyWith(isLoading: true);
    try {
      final tableName = AppConstants.ordersTable;

      if (tableName == 'sales') {
        await _supabaseClient
            .from('sales')
            .update({'status': 'CANCELLED'})
            .eq('id', orderId);
      } else {
        await _supabaseClient
            .from('orders')
            .update({'status': 'rejected'})
            .eq('id', orderId);
      }
      state = state.copyWith(clearOrder: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al rechazar: $e',
      );
    }
  }

  /// Actualizar estado del pedido
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    state = state.copyWith(isLoading: true);
    try {
      final tableName = AppConstants.ordersTable;

      if (tableName == 'sales') {
        // Mapear estado de delivery a estado de sale
        String? saleStatus;
        switch (newStatus) {
          case 'accepted':
            saleStatus = 'ACCEPTED';
            break;
          case 'picking_up':
          case 'picked_up':
            saleStatus = 'PREPARING';
            break;
          case 'delivering':
            saleStatus = 'DELIVERING';
            break;
          case 'delivered':
            saleStatus = 'DELIVERED';
            break;
          case 'rejected':
          case 'cancelled':
            saleStatus = 'CANCELLED';
            break;
        }
        if (saleStatus != null) {
          await _supabaseClient
              .from('sales')
              .update({'status': saleStatus})
              .eq('id', orderId);
        }
      } else {
        await _supabaseClient
            .from('orders')
            .update({'status': newStatus})
            .eq('id', orderId);
      }
      state = state.copyWith(clearOrder: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar: $e',
      );
    }
  }

  /// Limpiar el pedido actual
  void clearCurrentNewOrder() {
    state = state.copyWith(clearOrder: true);
  }

  /// Reintentar conexión
  void fetchNewOrder() {
    _listenForNewOrders();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}

/// Provider para el NewOrderNotifier
final newOrderProvider = StateNotifierProvider<NewOrderNotifier, NewOrderState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return NewOrderNotifier(supabaseClient, notificationService, ref);
});

// ============================================================================
// ACTIVE ORDER NOTIFIER
// ============================================================================

/// Estado del ActiveOrderNotifier
class ActiveOrderState {
  final List<Order> assignedOrders;
  final Order? activeOrder;
  final bool isLoading;
  final String? errorMessage;
  final List<bool> itemChecked;

  const ActiveOrderState({
    this.assignedOrders = const [],
    this.activeOrder,
    this.isLoading = false,
    this.errorMessage,
    this.itemChecked = const [],
  });

  ActiveOrderState copyWith({
    List<Order>? assignedOrders,
    Order? activeOrder,
    bool? isLoading,
    String? errorMessage,
    List<bool>? itemChecked,
    bool clearActiveOrder = false,
  }) {
    return ActiveOrderState(
      assignedOrders: assignedOrders ?? this.assignedOrders,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      itemChecked: itemChecked ?? this.itemChecked,
    );
  }
}

/// Notifier para manejar pedidos activos
class ActiveOrderNotifier extends StateNotifier<ActiveOrderState> {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _assignedOrdersSubscription;

  ActiveOrderNotifier(this._supabaseClient) : super(const ActiveOrderState()) {
    _startListeningToAssignedOrders();
  }

  void _startListeningToAssignedOrders() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    final tableName = AppConstants.ordersTable;

    // Para sales, escuchamos delivery_orders o filtramos por driver
    if (tableName == 'sales') {
      // Escuchar delivery_orders para pedidos activos del repartidor
      // NOTA: No se puede usar in_ en streams, escuchamos todos y filtramos
      final query = _supabaseClient
          .from('delivery_orders')
          .stream(primaryKey: ['id'])
          .eq('driver_id', userId);

      _assignedOrdersSubscription = query.listen(
        (data) async {
          final orders = <Order>[];

          for (final deliveryData in data) {
            // Obtener datos de la venta asociada
            final saleData = await _getSaleData(deliveryData['sale_id'] as String);
            if (saleData != null) {
              orders.add(Order.fromSalesJson(saleData, deliveryData));
            }
          }

          state = state.copyWith(assignedOrders: orders);

          if (state.activeOrder != null && !orders.any((o) => o.id == state.activeOrder!.id)) {
            state = state.copyWith(clearActiveOrder: true);
          }
        },
        onError: (error) {
          state = state.copyWith(errorMessage: 'Error: $error');
        },
      );
    } else {
      // Legacy: listen en orders
      _assignedOrdersSubscription = _supabaseClient
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('driver_id', userId)
          .listen(
        (data) {
          final activeStatuses = ['accepted', 'arrived_at_restaurant', 'picking_up', 'picked_up', 'delivering'];

          final orders = data.map((map) => Order.fromJson(map))
              .where((order) => activeStatuses.contains(order.status))
              .toList();

          state = state.copyWith(assignedOrders: orders);

          if (state.activeOrder != null && !orders.any((o) => o.id == state.activeOrder!.id)) {
            state = state.copyWith(clearActiveOrder: true);
          }
        },
        onError: (error) {
          state = state.copyWith(errorMessage: 'Error: $error');
        },
      );
    }
  }

  Future<Map<String, dynamic>?> _getSaleData(String saleId) async {
    try {
      return await _supabaseClient
          .from('sales')
          .select()
          .eq('id', saleId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  void setActiveOrder(Order order) {
    state = state.copyWith(
      activeOrder: order,
      itemChecked: order.items != null
          ? List<bool>.filled(order.items!.length, false)
          : [],
    );
  }

  void setItemChecked(int index, bool value) {
    final newChecked = List<bool>.from(state.itemChecked);
    if (index >= 0 && index < newChecked.length) {
      newChecked[index] = value;
      state = state.copyWith(itemChecked: newChecked);
    }
  }

  Future<void> updateOrderStatus(String newStatus) async {
    if (state.activeOrder == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final tableName = AppConstants.ordersTable;

      if (tableName == 'sales') {
        // Mapear estado
        String? saleStatus;
        switch (newStatus) {
          case 'arrived_at_restaurant':
          case 'picking_up':
            saleStatus = 'PREPARING';
            break;
          case 'picked_up':
            saleStatus = 'READY';
            break;
          case 'delivering':
            saleStatus = 'DELIVERING';
            break;
          case 'delivered':
            saleStatus = 'DELIVERED';
            break;
          default:
            saleStatus = newStatus.toUpperCase();
        }
        if (saleStatus != null) {
          await _supabaseClient
              .from('sales')
              .update({'status': saleStatus})
              .eq('id', state.activeOrder!.id);
        }
      } else {
        await _supabaseClient
            .from('orders')
            .update({'status': newStatus})
            .eq('id', state.activeOrder!.id);
      }
      state = state.copyWith(isLoading: false, clearActiveOrder: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
    }
  }

  @override
  void dispose() {
    _assignedOrdersSubscription?.cancel();
    super.dispose();
  }
}

/// Provider para el ActiveOrderNotifier
final activeOrderProvider = StateNotifierProvider<ActiveOrderNotifier, ActiveOrderState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ActiveOrderNotifier(supabaseClient);
});
