
// order_item_model.dart (Data Model)
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/data/models/product_model.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required String id,
    required String orderId,
    required ProductModel product,
    required int quantity,
    required double priceAtPurchase,
  }) : super(
          id: id,
          orderId: orderId,
          product: product,
          quantity: quantity,
          priceAtPurchase: priceAtPurchase,
        );

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      product: ProductModel.fromJson(json['products']), // Supabase joins 'products' table
      quantity: json['quantity'] as int,
      priceAtPurchase: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': product.id, // Only send ID when creating order item
      'quantity': quantity,
      'price': priceAtPurchase,
    };
  }

  OrderItem toEntity() {
    return OrderItem(
      id: id,
      orderId: orderId,
      product: product.toEntity(),
      quantity: quantity,
      priceAtPurchase: priceAtPurchase,
    );
  }
}