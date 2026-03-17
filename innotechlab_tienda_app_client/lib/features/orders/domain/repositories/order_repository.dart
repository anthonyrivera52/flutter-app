import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:flutter_app/features/orders/domain/models/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, PaginatedOrders>> getUserOrders({
    String? cursor,
    int limit = 10,
  });
  Future<Either<Failure, AppOrder>> getOrderById(String orderId);
}
