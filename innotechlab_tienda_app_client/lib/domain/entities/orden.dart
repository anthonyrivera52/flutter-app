
import 'package:equatable/equatable.dart';
import 'package:flutter_app/domain/entities/orden_item.dart';

class Orden extends Equatable {
  final String id;
  final String userId;
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

  const Orden({
    required this.id,
    required this.userId,
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
  });

  @override
  List<Object> get props => [
        id,
        userId,
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
      ];
}