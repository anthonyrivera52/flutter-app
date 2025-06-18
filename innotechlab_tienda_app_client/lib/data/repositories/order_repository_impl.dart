import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/datasources/order_remote_datasource.dart';
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


abstract class OrderRepository {
  Future<Either<Failure, List<Orden>>> getUserOrders();
  Future<Either<Failure, Orden>> getOrderById(String orderId);
}

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl(this.remoteDataSource);

  // Future<Either<Failure, bool>> placeOrder({
  //   required String userId,
  //   required List<CartItem> items,
  //   required double total,
  //   required String address,
  //   required String paymentMethod,
  // }) async {
  //   try {
  //     await remoteDataSource.createOrder(
  //       cartItems: cartItems,
  //       totalAmount: totalAmount,
  //       shippingAddress: shippingAddress,
  //       shippingLatitude: shippingLatitude,
  //       shippingLongitude: shippingLongitude,
  //       notes: notes,
  //     );
  //     return const Right(null);
  //   } on ServerFailure catch (e) {
  //     return Left(ServerFailure(e.message));
  //   }
  // }
  
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
      return Right(orders.cast<Orden>());
    } catch (e) {
      return Left(ServerFailure('Failed to get user orders: ${e.toString()}'));
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrderRepositoryImpl(remoteDataSource);
});