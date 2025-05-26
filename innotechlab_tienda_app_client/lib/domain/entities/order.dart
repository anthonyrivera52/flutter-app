
// order.dart (Domain Entity)
import 'package:equatable/equatable.dart';
import 'package:mi_tienda/domain/entities/product.dart'; // To reuse Product entity

class Order extends Equatable {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final double shippingLatitude;
  final double shippingLongitude;
  final double storeLatitude;
  final double storeLongitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items; // List of order items

  const Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.shippingLatitude,
    required this.shippingLongitude,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  @override
  List<Object> get props => [
        id,
        userId,
        totalAmount,
        status,
        shippingAddress,
        shippingLatitude,
        shippingLongitude,
        storeLatitude,
        storeLongitude,
        createdAt,
        updatedAt,
        items,
      ];
}

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final Product product; // Using the Product entity
  final int quantity;
  final double priceAtPurchase; // Price at the time of purchase

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.product,
    required this.quantity,
    required this.priceAtPurchase,
  });

  @override
  List<Object> get props => [id, orderId, product, quantity, priceAtPurchase];
}
