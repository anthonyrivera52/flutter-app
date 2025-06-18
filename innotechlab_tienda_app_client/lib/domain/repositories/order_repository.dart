import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/datasources/order_remote_datasource.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


abstract class OrderRepository {
  Future<Either<Failure, List<Orden>>> getUserOrders();
  Future<Either<Failure, Orden>> getOrderById(String orderId);
}

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Orden>> getOrderById(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderById(orderId);
      return Right(order);
    } catch (e) {
      return Left(ServerFailure('Failed to get order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Orden>>> getUserOrders() async {
    try {
      final orders = await remoteDataSource.getUserOrders();
      return Right(orders);
    } catch (e) {
      return Left(ServerFailure('Failed to get user orders: ${e.toString()}'));
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrderRepositoryImpl(remoteDataSource);
});