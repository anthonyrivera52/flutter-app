import 'package:equatable/equatable.dart';
import 'package:flutter_app/domain/entities/orden_item.dart';

class Orden extends Equatable {
  final String id;
  final String userId;
  final String orderCode; // Código aleatorio para verificación de entrega
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

  // Campos adicionales para información del domiciliario
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhotoUrl;
  final String? vehicleType;
  final String? vehiclePlate;

  // Campos para desglose de costos
  final double? subtotalAmount;
  final double? shippingAmount;
  final double? taxIvaAmount;
  final double? tipAmount;

  // Campos adicionales
  final String? verificationCode;
  final String? restaurantName;
  final String? restaurantAddress;
  final DateTime? driverAssignedAt;
  final DateTime? pickedUpAt;

  const Orden({
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
    this.restaurantName,
    this.restaurantAddress,
    this.driverAssignedAt,
    this.pickedUpAt,
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
    restaurantName,
    restaurantAddress,
    driverAssignedAt,
    pickedUpAt,
  ];
}
