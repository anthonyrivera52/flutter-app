
// order_model.dart (Data Model)
import 'package:dartz/dartz.dart';
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/data/models/order_item_model.dart';
import 'package:mi_tienda/data/models/product_model.dart';

class OrderModel extends Order {
  const OrderModel({
    required String id,
    required String userId,
    required double totalAmount,
    required String status,
    required String shippingAddress,
    required double shippingLatitude,
    required double shippingLongitude,
    required double storeLatitude,
    required double storeLongitude,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<OrderItemModel> items = const [],
  }) : super(
          id: id,
          userId: userId,
          totalAmount: totalAmount,
          status: status,
          shippingAddress: shippingAddress,
          shippingLatitude: shippingLatitude,
          shippingLongitude: shippingLongitude,
          storeLatitude: storeLatitude,
          storeLongitude: storeLongitude,
          createdAt: createdAt,
          updatedAt: updatedAt,
          items: items,
        );

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> items = [];
    if (json['order_items'] != null) {
      items = (json['order_items'] as List)
          .map((itemJson) => OrderItemModel.fromJson(itemJson))
          .toList();
    }

    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      shippingAddress: json['shipping_address'] as String,
      shippingLatitude: (json['shipping_latitude'] as num).toDouble(),
      shippingLongitude: (json['shipping_longitude'] as num).toDouble(),
      storeLatitude: (json['store_latitude'] as num).toDouble(),
      storeLongitude: (json['store_longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'status': status,
      'shipping_address': shippingAddress,
      'shipping_latitude': shippingLatitude,
      'shipping_longitude': shippingLongitude,
      'store_latitude': storeLatitude,
      'store_longitude': storeLongitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'order_items': (items as List<OrderItemModel>).map((e) => e.toJson()).toList(),
    };
  }

  Order toEntity() {
    return Order(
      id: id,
      userId: userId,
      totalAmount: totalAmount,
      status: status,
      shippingAddress: shippingAddress,
      shippingLatitude: shippingLatitude,
      shippingLongitude: shippingLongitude,
      storeLatitude: storeLatitude,
      storeLongitude: storeLongitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items.map((e) => e.toEntity()).toList(),
    );
  }
}
