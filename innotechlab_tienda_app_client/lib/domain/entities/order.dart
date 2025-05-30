import 'package:equatable/equatable.dart';
import 'package:flutter_app/domain/entities/cartItem.dart';

/// Represents a user's order.
class Order extends Equatable {
  final String id;
  final String userId;
  final DateTime orderDate;
  final List<CartItem> items; // Items included in the order
  final double totalAmount;
  final String status; // e.g., "Pending", "Processing", "Shipped", "Delivered", "Cancelled"
  final String deliveryAddress;

  const Order({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
  });

  Order copyWith({
    String? id,
    String? userId,
    DateTime? orderDate,
    List<CartItem>? items,
    double? totalAmount,
    String? status,
    String? deliveryAddress,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  @override
  List<Object> get props => [id, userId, orderDate, items, totalAmount, status, deliveryAddress];
}