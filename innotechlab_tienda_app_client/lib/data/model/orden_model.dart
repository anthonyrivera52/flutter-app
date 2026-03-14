import 'package:flutter_app/domain/entities/orden.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_app/data/model/orden_item_model.dart';

class OrdenModel extends Orden {
  const OrdenModel({
    required super.id,
    required super.userId,
    required super.orderCode,
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
    super.driverId,
    super.driverName,
    super.driverPhone,
    super.driverPhotoUrl,
    super.vehicleType,
    super.vehiclePlate,
    super.subtotalAmount,
    super.shippingAmount,
    super.taxIvaAmount,
    super.tipAmount,
    super.verificationCode,
    super.restaurantName,
    super.restaurantAddress,
    super.driverAssignedAt,
    super.pickedUpAt,
  });

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    // Parse items from sale_items (or order_items for backward compatibility)
    List<OrdenItemModel> items = [];
    if (json['sale_items'] != null) {
      items = (json['sale_items'] as List)
          .map((itemJson) => OrdenItemModel.fromJson(itemJson))
          .toList();
    } else if (json['order_items'] != null) {
      items = (json['order_items'] as List)
          .map((itemJson) => OrdenItemModel.fromJson(itemJson))
          .toList();
    }

    // Parse driver information if available
    String? driverId;
    String? driverName;
    String? driverPhone;
    String? driverPhotoUrl;
    String? vehicleType;
    String? vehiclePlate;

    if (json['driver'] != null && json['driver'] is Map<String, dynamic>) {
      final driverJson = json['driver'] as Map<String, dynamic>;
      driverId = driverJson['id'] as String?;
      driverName = driverJson['name'] as String?;
      driverPhone = driverJson['phone'] as String?;
      driverPhotoUrl = driverJson['photo_url'] as String?;
      vehicleType = driverJson['vehicle_type'] as String?;
      vehiclePlate = driverJson['vehicle_plate'] as String?;
    }

    // Parse shipping address as JSON if it's a string (for backward compatibility)
    String shippingAddress = '';
    if (json['shipping_address'] is String) {
      shippingAddress = json['shipping_address'] as String;
    } else if (json['shipping_address'] is Map<String, dynamic>) {
      final addressJson = json['shipping_address'] as Map<String, dynamic>;
      shippingAddress =
          addressJson['address_line1'] as String? ??
          addressJson['formatted_address'] as String? ??
          '';
    }

    return OrdenModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderCode:
          json['order_code'] as String? ??
          json['verification_code'] as String? ??
          '',
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      shippingAddress: shippingAddress,
      shippingLatitude: (json['shipping_latitude'] as num?)?.toDouble() ?? 0.0,
      shippingLongitude:
          (json['shipping_longitude'] as num?)?.toDouble() ?? 0.0,
      storeLatitude: (json['store_latitude'] as num?)?.toDouble() ?? 0.0,
      storeLongitude: (json['store_longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: items,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverPhotoUrl: driverPhotoUrl,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      subtotalAmount: json['subtotal_amount'] != null
          ? (json['subtotal_amount'] as num).toDouble()
          : null,
      shippingAmount: json['shipping_amount'] != null
          ? (json['shipping_amount'] as num).toDouble()
          : null,
      taxIvaAmount: json['tax_iva_amount'] != null
          ? (json['tax_iva_amount'] as num).toDouble()
          : null,
      tipAmount: json['tip_amount'] != null
          ? (json['tip_amount'] as num).toDouble()
          : null,
      verificationCode: json['verification_code'] as String?,
      driverAssignedAt: json['driver_assigned_at'] != null
          ? DateTime.parse(json['driver_assigned_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_code': orderCode,
      'total_amount': totalAmount,
      'status': status,
      'shipping_address': shippingAddress,
      'shipping_latitude': shippingLatitude,
      'shipping_longitude': shippingLongitude,
      'store_latitude': storeLatitude,
      'store_longitude': storeLongitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sale_items': (items as List<OrdenItemModel>)
          .map((e) => e.toJson())
          .toList(),
      if (subtotalAmount != null) 'subtotal_amount': subtotalAmount,
      if (shippingAmount != null) 'shipping_amount': shippingAmount,
      if (taxIvaAmount != null) 'tax_iva_amount': taxIvaAmount,
      if (tipAmount != null) 'tip_amount': tipAmount,
      if (verificationCode != null) 'verification_code': verificationCode,
      if (driverAssignedAt != null)
        'driver_assigned_at': driverAssignedAt!.toIso8601String(),
      if (pickedUpAt != null) 'picked_up_at': pickedUpAt!.toIso8601String(),
    };
  }

  Orden toEntity() {
    return Orden(
      id: id.toString(),
      userId: userId,
      orderCode: orderCode,
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
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverPhotoUrl: driverPhotoUrl,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      subtotalAmount: subtotalAmount,
      shippingAmount: shippingAmount,
      taxIvaAmount: taxIvaAmount,
      tipAmount: tipAmount,
      verificationCode: verificationCode,
      driverAssignedAt: driverAssignedAt,
      pickedUpAt: pickedUpAt,
    );
  }
}
