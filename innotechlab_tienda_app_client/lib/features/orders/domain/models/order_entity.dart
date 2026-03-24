import 'package:equatable/equatable.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';

enum OrderPaymentMethod { cash, online }

enum OrderPaymentStatus {
  pending,
  processing,
  paid,
  failed,
  refunded,
  partiallyRefunded,
}

class OrderPaymentInfo extends Equatable {
  final OrderPaymentMethod? paymentMethod;
  final OrderPaymentStatus? paymentStatus;
  final String? transactionId;
  final String? gatewayTransactionId;
  final DateTime? paidAt;

  const OrderPaymentInfo({
    this.paymentMethod,
    this.paymentStatus,
    this.transactionId,
    this.gatewayTransactionId,
    this.paidAt,
  });

  bool get isPaid => paymentStatus == OrderPaymentStatus.paid;
  bool get isOnline => paymentMethod == OrderPaymentMethod.online;
  bool get isCash => paymentMethod == OrderPaymentMethod.cash;
  bool get isFailed => paymentStatus == OrderPaymentStatus.failed;

  String get paymentMethodText {
    if (paymentMethod == OrderPaymentMethod.online) {
      return 'Pago en línea';
    }
    return 'Efectivo';
  }

  @override
  List<Object?> get props => [
    paymentMethod,
    paymentStatus,
    transactionId,
    gatewayTransactionId,
    paidAt,
  ];
}

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final Product product;
  final int quantity;
  final double priceAtPurchase;

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

class AppOrder extends Equatable {
  final String id;
  final String userId;
  final String orderCode;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final double shippingLatitude;
  final double shippingLongitude;
  final double storeLatitude;
  final double storeLongitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhotoUrl;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? subtotalAmount;
  final double? shippingAmount;
  final double? taxIvaAmount;
  final double? tipAmount;
  final String? verificationCode;
  final DateTime? driverAssignedAt;
  final DateTime? pickedUpAt;
  final OrderPaymentInfo? paymentInfo;

  const AppOrder({
    required this.id,
    required this.userId,
    required this.orderCode,
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
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverPhotoUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.subtotalAmount,
    this.shippingAmount,
    this.taxIvaAmount,
    this.tipAmount,
    this.verificationCode,
    this.driverAssignedAt,
    this.pickedUpAt,
    this.paymentInfo,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    orderCode,
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
    driverId,
    driverName,
    driverPhone,
    driverPhotoUrl,
    vehicleType,
    vehiclePlate,
    subtotalAmount,
    shippingAmount,
    taxIvaAmount,
    tipAmount,
    verificationCode,
    driverAssignedAt,
    pickedUpAt,
    paymentInfo,
  ];
}
