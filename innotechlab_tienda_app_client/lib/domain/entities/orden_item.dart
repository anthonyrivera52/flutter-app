import 'package:equatable/equatable.dart';
import 'package:flutter_app/domain/entities/product.dart';

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