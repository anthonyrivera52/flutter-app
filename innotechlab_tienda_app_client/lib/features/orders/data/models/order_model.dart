import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/products/data/models/product_model.dart';

class OrderItemModel extends OrderItem {

  const OrderItemModel({
    required super.id,
    required super.orderId,
    required super.product,
    required super.quantity,
    required super.priceAtPurchase,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['sale_id'] as String? ?? json['order_id'] as String? ?? '',
      product: ProductModel.fromJson(
        json['products'] as Map<String, dynamic>? ?? {},
      ),
      quantity: json['quantity'] as int,
      priceAtPurchase: (json['unit_price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

class OrderModel extends AppOrder {
  const OrderModel({
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
    super.items,
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
    super.driverAssignedAt,
    super.pickedUpAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items
    List<OrderItemModel> items = [];
    final rawItems = json['sale_items'] ?? json['order_items'];
    if (rawItems is List) {
      items = rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse driver
    String? driverId, driverName, driverPhone, driverPhotoUrl, vehicleType, vehiclePlate;
    if (json['driver'] is Map<String, dynamic>) {
      final d = json['driver'] as Map<String, dynamic>;
      driverId = d['id'] as String?;
      driverName = d['name'] as String?;
      driverPhone = d['phone'] as String?;
      driverPhotoUrl = d['photo_url'] as String?;
      vehicleType = d['vehicle_type'] as String?;
      vehiclePlate = d['vehicle_plate'] as String?;
    }

    // Parse shipping address
    String shippingAddress = '';
    if (json['shipping_address'] is String) {
      shippingAddress = json['shipping_address'] as String;
    } else if (json['shipping_address'] is Map<String, dynamic>) {
      final addr = json['shipping_address'] as Map<String, dynamic>;
      shippingAddress = addr['address_line1'] as String? ??
          addr['formatted_address'] as String? ??
          '';
    }

    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderCode: json['order_code'] as String? ??
          json['verification_code'] as String? ??
          '',
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      shippingAddress: shippingAddress,
      shippingLatitude: (json['shipping_latitude'] as num?)?.toDouble() ?? 0.0,
      shippingLongitude: (json['shipping_longitude'] as num?)?.toDouble() ?? 0.0,
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
      subtotalAmount: (json['subtotal_amount'] as num?)?.toDouble(),
      shippingAmount: (json['shipping_amount'] as num?)?.toDouble(),
      taxIvaAmount: (json['tax_iva_amount'] as num?)?.toDouble(),
      tipAmount: (json['tip_amount'] as num?)?.toDouble(),
      verificationCode: json['verification_code'] as String?,
      driverAssignedAt: json['driver_assigned_at'] != null
          ? DateTime.parse(json['driver_assigned_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
    );
  }

  AppOrder toEntity() => AppOrder(
    id: id,
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
    items: items,
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
