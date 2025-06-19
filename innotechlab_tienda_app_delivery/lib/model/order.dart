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
      String locationString = json['restaurant_location'] as String;
      // Elimina los paréntesis y divide por la coma
      locationString = locationString.replaceAll('(', '').replaceAll(')', '');
      List<String> parts = locationString.split(',');

      // Convierte a double
      double latitude = double.parse(parts[0]);
      double longitude = double.parse(parts[1]);

      String locationCustomer = json['customer_location'] as String;
      // Elimina los paréntesis y divide por la coma
      locationCustomer = locationCustomer.replaceAll('(', '').replaceAll(')', '');
      List<String> partsCustomer = locationCustomer.split(',');

      // Convierte a double
      double latitudeCustomer = double.parse(partsCustomer[0]);
      double longitudeCustomer = double.parse(partsCustomer[1]);
      
      return Order(
        id: json['id'] as String,
        customerName: json['customer_name'] as String,
        restaurantName: json['restaurant_name'] as String,
        restaurantAddress: json['restaurant_address'] as String,
        restaurantLocation: LatLng(latitude, longitude),
        customerAddress: json['customer_address'] as String,
        customerPhone: json['customer_phone'] as String,
        customerLocation: LatLng(latitudeCustomer, longitudeCustomer),
        orderType: json['order_type'] as String,
        estimatedEarnings: json['estimated_earnings'] as double,
        estimatedTimeMinutes: json['estimated_time_minutes'] as int,
        distanceKm: json['distance_km'] as double,
        items: List<String>.from(json['items']),
        status: json['status'] as String,
        totalAmount: json['total_amount'] as double,
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