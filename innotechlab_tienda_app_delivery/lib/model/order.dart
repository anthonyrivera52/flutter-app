import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery_app_mvvm/core/utils/constants.dart';

// Representa un pedido dentro de la aplicación
class Order {
  final String id;
  final String? saleId; // ID de la venta en Supabase (sales)
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
  List<OrderItem>? items; // Para pedidos de supermercado/farmacia
  final double totalAmount;
  // Estado del pedido desde la perspectiva del repartidor
  String status; // Ej: "pending", "accepted", "picking_up", "delivering", "delivered"
  final String? pickupCode;
  final String? deliveryCode;

  Order({
    required this.id,
    this.saleId,
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
    this.totalAmount = 0,
    this.pickupCode,
    this.deliveryCode,
  });

  /// Factory para crear Order desde formato legacy (tabla orders)
  factory Order.fromLegacyJson(Map<String, dynamic> json) {
    String locationString = json['restaurant_location'] as String;
    locationString = locationString.replaceAll('(', '').replaceAll(')', '');
    List<String> parts = locationString.split(',');

    double latitude = double.parse(parts[0]);
    double longitude = double.parse(parts[1]);

    String locationCustomer = json['customer_location'] as String;
    locationCustomer = locationCustomer.replaceAll('(', '').replaceAll(')', '');
    List<String> partsCustomer = locationCustomer.split(',');

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
      items: (json['items'] as List<dynamic>?)
          ?.map((itemJson) {
            if (itemJson is Map<String, dynamic>) {
              return OrderItem.fromJson(itemJson);
            } else if (itemJson is String) {
              final parts = itemJson.split(' x');
              final name = parts[0];
              final quantity = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
              return OrderItem(name: name, quantity: quantity, price: 0, unit: '');
            } else {
              throw Exception('Formato de item desconocido: $itemJson');
            }
          }).toList() ?? [],
      status: json['status'] as String,
      totalAmount: json['total_amount'] as double,
      pickupCode: json['pickup_code'] as String?,
      deliveryCode: json['delivery_code'] as String?,
    );
  }

  /// Factory para crear Order desde sales + delivery_orders
  factory Order.fromSalesJson(Map<String, dynamic> saleJson, Map<String, dynamic>? deliveryData) {
    final deliveryMetadata = saleJson['delivery_metadata'] as Map<String, dynamic>? ?? {};
    final shippingAddress = saleJson['shipping_address'] as Map<String, dynamic>? ?? {};

    double customerLat = deliveryMetadata['customer_latitude'] as double? ??
        shippingAddress['latitude'] as double? ?? 0.0;
    double customerLng = deliveryMetadata['customer_longitude'] as double? ??
        shippingAddress['longitude'] as double? ?? 0.0;

    String restaurantName = deliveryMetadata['restaurant_name'] as String? ??
        saleJson['store_name'] as String? ?? 'Restaurante';
    String restaurantAddress = deliveryMetadata['restaurant_address'] as String? ?? '';

    double restaurantLat = deliveryMetadata['restaurant_latitude'] as double? ?? 0.0;
    double restaurantLng = deliveryMetadata['restaurant_longitude'] as double? ?? 0.0;

    double tip = (saleJson['tip'] as num?)?.toDouble() ?? 0.0;
    double deliveryFee = (deliveryMetadata['delivery_fee'] as num?)?.toDouble() ??
        (saleJson['shipping_amount'] as num?)?.toDouble() ?? 2.0;
    double estimatedEarnings = tip + deliveryFee;

    double distanceKm = 0.0;
    if (restaurantLat != 0.0 && restaurantLng != 0.0 && customerLat != 0.0 && customerLng != 0.0) {
      distanceKm = _calculateDistance(restaurantLat, restaurantLng, customerLat, customerLng);
    }

    double totalAmount = (saleJson['grand_total'] as num?)?.toDouble() ??
        (saleJson['total_amount'] as num?)?.toDouble() ?? 0.0;

    String status = _mapSaleStatusToDeliveryStatus(saleJson['status'] as String?);

    return Order(
      id: saleJson['id'] as String,
      saleId: saleJson['id'] as String,
      customerName: deliveryData?['customer_name'] as String? ??
          shippingAddress['name'] as String? ?? 'Cliente',
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantLocation: LatLng(restaurantLat, restaurantLng),
      customerAddress: deliveryData?['customer_address'] as String? ??
          shippingAddress['address'] as String? ?? shippingAddress['street'] as String? ?? '',
      customerPhone: deliveryData?['customer_phone'] as String? ??
          shippingAddress['phone'] as String? ?? '',
      customerLocation: LatLng(customerLat, customerLng),
      orderType: saleJson['order_type'] as String? ?? 'DELIVERY',
      estimatedEarnings: estimatedEarnings,
      estimatedTimeMinutes: ((distanceKm * 2) + 5).round(),
      distanceKm: distanceKm,
      status: deliveryData?['status'] as String? ?? status,
      totalAmount: totalAmount,
      pickupCode: deliveryData?['pickup_code'] as String? ??
          saleJson['verification_code'] as String?,
      deliveryCode: deliveryData?['delivery_code'] as String?,
    );
  }

  /// Método de compatibilidad - detecta el formato automáticamente
  factory Order.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('restaurant_location') && json['restaurant_location'] is String) {
      return Order.fromLegacyJson(json);
    }
    return Order.fromSalesJson(json, null);
  }

  static String _mapSaleStatusToDeliveryStatus(String? saleStatus) {
    switch (saleStatus?.toUpperCase()) {
      case 'NEW':
      case 'PENDING':
      case 'CONFIRMED':
        return AppConstants.deliveryStatusPending;
      case 'ACCEPTED':
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

  // Haversine formula simple
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = (lat2 - lat1) * 3.141592653589793 / 180;
    final double dLon = (lon2 - lon1) * 3.141592653589793 / 180;
    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(lat1 * 3.141592653589793 / 180) *
            _cos(lat2 * 3.141592653589793 / 180) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  static double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  static double _atan(double x) => x - (x * x * x) / 3 + (x * x * x * x * x) / 5;

  Order copyWith({
    String? id,
    String? saleId,
    String? restaurantName,
    String? restaurantAddress,
    LatLng? restaurantLocation,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    LatLng? customerLocation,
    String? orderType,
    double? estimatedEarnings,
    int? estimatedTimeMinutes,
    double? distanceKm,
    List<OrderItem>? items,
    String? status,
    double? totalAmount,
    String? pickupCode,
    String? deliveryCode,
  }) {
    return Order(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      customerLocation: customerLocation ?? this.customerLocation,
      orderType: orderType ?? this.orderType,
      estimatedEarnings: estimatedEarnings ?? this.estimatedEarnings,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      items: items ?? this.items,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      pickupCode: pickupCode ?? this.pickupCode,
      deliveryCode: deliveryCode ?? this.deliveryCode,
    );
  }
}

// Assuming you have an OrderItem model
class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String unit;

  OrderItem({required this.name, required this.quantity, required this.price, required this.unit});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}
