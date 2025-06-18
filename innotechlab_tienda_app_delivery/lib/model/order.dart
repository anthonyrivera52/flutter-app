import 'package:google_maps_flutter/google_maps_flutter.dart';

// Representa un pedido dentro de la aplicación
class Order {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final LatLng restaurantLocation;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final LatLng customerLocation;
  final String orderType; // Ej: "Comida", "Supermercado", "Farmacia"
  final double estimatedEarnings;
  final int estimatedTimeMinutes;
  final double distanceKm;
  List<String>? items; // Para pedidos de supermercado/farmacia

  // Estado del pedido desde la perspectiva del repartidor
  String status; // Ej: "pending", "accepted", "picking_up", "delivering", "delivered"

  Order({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantLocation,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.customerLocation,
    required this.orderType,
    required this.estimatedEarnings,
    required this.estimatedTimeMinutes,
    required this.distanceKm,
    this.items,
    this.status = 'pending', // Estado inicial
  });

  // Método para crear una copia de la orden con un nuevo estado
  Order copyWith({String? status}) {
    return Order(
      id: id,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantLocation: restaurantLocation,
      customerName: customerName,
      customerAddress: customerAddress,
      customerPhone: customerPhone,
      customerLocation: customerLocation,
      orderType: orderType,
      estimatedEarnings: estimatedEarnings,
      estimatedTimeMinutes: estimatedTimeMinutes,
      distanceKm: distanceKm,
      items: items,
      status: status ?? this.status,
    );
  }
}