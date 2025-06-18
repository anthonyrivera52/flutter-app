import 'package:flutter_app/domain/entities/orden.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_app/data/model/orden_item_model.dart';

class OrdenModel extends Orden {
  const OrdenModel({
    required super.id,
    required super.userId,
    required super.totalAmount,
    required super.status,
    required super.shippingAddress,
    required super.shippingLatitude,
    required super.shippingLongitude,
    required super.storeLatitude,
    required super.storeLongitude,
    required super.createdAt,
    required super.updatedAt,
    List<OrdenItemModel> items = const [],
  });

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    List<OrdenItemModel> items = [];
    if (json['order_items'] != null) {
      items = (json['order_items'] as List)
          .map((itemJson) => OrdenItemModel.fromJson(itemJson))
          .toList();
    }

    return OrdenModel(
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
      'order_items': (items as List<OrdenItemModel>).map((e) => e.toJson()).toList(),
    };
  }

  Orden toEntity() {
    return Orden(
      id: id.toString(),
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
      items: items.map((e) => e).toList(),
    );
  }
}