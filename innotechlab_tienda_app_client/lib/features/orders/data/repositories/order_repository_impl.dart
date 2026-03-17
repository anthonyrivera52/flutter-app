import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/orders/domain/repositories/order_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _dataSource;
  OrderRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, PaginatedOrders>> getUserOrders({
    String? cursor,
    int limit = 10,
  }) async {
    try {
      return Right(await _dataSource.getUserOrders(cursor: cursor, limit: limit));
    } catch (e) {
      return Left(ServerFailure('Error al obtener pedidos: $e'));
    }
  }

  @override
  Future<Either<Failure, AppOrder>> getOrderById(String orderId) async {
    try {
      return Right(await _dataSource.getOrderById(orderId));
    } catch (e) {
      return Left(ServerFailure('Error al obtener pedido: $e'));
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderRemoteDataSourceProvider));
});
