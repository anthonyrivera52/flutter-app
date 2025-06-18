import 'dart:async';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/service/order_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Implementación de un servicio de órdenes usando datos mock
class MockOrderService implements OrderService {
  // Lista de órdenes mock
  static final List<Order> _mockOrders = [
    Order(
      id: 'ORD001',
      restaurantName: 'Pizzeria La Delicia',
      restaurantAddress: 'Cra 45 #30-10, Sabaneta',
      restaurantLocation: const LatLng(6.167885, -75.589885), // Ubicación simulada cerca de Sabaneta
      customerName: 'Juan Pérez',
      customerAddress: 'Calle 50 #15-20, Envigado',
      customerLocation: const LatLng(6.177000, -75.578000), // Ubicación simulada cerca de Envigado
      orderType: 'Comida',
      estimatedEarnings: 8.50,
      estimatedTimeMinutes: 25,
      distanceKm: 4.2,
      customerPhone: ''
    ),
    Order(
      id: 'ORD002',
      restaurantName: 'Supermercado Central',
      restaurantAddress: 'Av. El Poblado #10-5, Sabaneta',
      restaurantLocation: const LatLng(6.155000, -75.590000),
      customerName: 'Ana García',
      customerAddress: 'Diagonal 32 #50-1, La Estrella',
      customerLocation: const LatLng(6.130000, -75.610000),
      orderType: 'Supermercado',
      estimatedEarnings: 12.00,
      estimatedTimeMinutes: 40,
      distanceKm: 7.5,
      items: [
        'Leche entera x1',
        'Pan tajado x1',
        'Huevos x12',
        'Manzanas rojas x3',
      ],
      customerPhone: ''
    ),
    Order(
      id: 'ORD003',
      restaurantName: 'Farmacia Saludable',
      restaurantAddress: 'Cl. 77 Sur #48-2, La Estrella',
      restaurantLocation: const LatLng(6.115000, -75.630000),
      customerName: 'Carlos López',
      customerAddress: 'Carrera 43A #2 Sur-10, Itagüí',
      customerLocation: const LatLng(6.160000, -75.600000),
      orderType: 'Farmacia',
      estimatedEarnings: 9.00,
      estimatedTimeMinutes: 30,
      distanceKm: 5.0,
      items: [
        'Acetaminofén x1',
        'Vitamina C x1',
        'Alcohol antiséptico x1',
      ],
      customerPhone: ''
    ),
  ];

  // Índice para simular nuevas órdenes
  int _orderIndex = 0;

  @override
  Future<Order?> fetchNewOrder() async {
    // Simula un retardo de red
    await Future.delayed(const Duration(seconds: 3));
    if (_orderIndex < _mockOrders.length) {
      final newOrder = _mockOrders[_orderIndex];
      _orderIndex++;
      return newOrder;
    }
    return null; // No hay más órdenes mock
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Simula un retardo de red
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockOrders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      _mockOrders[index] = _mockOrders[index].copyWith(status: newStatus);
      print('Estado de orden $orderId actualizado a: $newStatus');
    }
  }
}