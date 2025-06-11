
// order_item_model.dart (Data Model)

import 'package:flutter_app/data/model/product_model.dart';
import 'package:flutter_app/domain/entities/orden_item.dart';

class OrdenItemModel extends OrderItem {
  const OrdenItemModel({
    required super.id,
    required super.orderId,
    required ProductModel super.product,
    required super.quantity,
    required super.priceAtPurchase,
  });

  factory OrdenItemModel.fromJson(Map<String, dynamic> json) {
    return OrdenItemModel(
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
      product: product,
      quantity: quantity,
      priceAtPurchase: priceAtPurchase,
    );
  }
}