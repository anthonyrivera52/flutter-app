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
  final double totalAmount;
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
    this.totalAmount = 0
  });

    factory Order.fromJson(Map<String, dynamic> json) {
      return Order(
        id: json['id'] as String,
        customerName: json['customer_name'] as String,
        restaurantName: json['restaurantName'] as String,
        restaurantAddress: json['restaurantAddress'] as String,
        restaurantLocation: json['restaurantLocation'] as LatLng,
        customerAddress: json['customerAddress'] as String,
        customerPhone: json['customerPhone'] as String,
        customerLocation: json['customerLocation'] as LatLng,
        orderType: json['orderType'] as String,
        estimatedEarnings: json['estimatedEarnings'] as double,
        estimatedTimeMinutes: json['estimatedTimeMinutes'] as int,
        distanceKm: json['distanceKm'] as double,
        items: json['items'] as List<String>,
        status: json['status'] as String,
        totalAmount: json['totalAmount'] as double,
      );
  }

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
      totalAmount: totalAmount,
    );
  }
}