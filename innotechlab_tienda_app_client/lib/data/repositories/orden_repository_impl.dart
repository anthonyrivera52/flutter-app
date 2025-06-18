
// order_repository_impl.dart (Data Repository Impl)
import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/datasources/orden_remote_datasource.dart';
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_app/domain/repositories/orden_repository.dart';

class OrdenRepositoryImpl implements OrdenRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrdenRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> placeOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String shippingAddress,
    required double shippingLatitude,
    required double shippingLongitude,
    String? notes,
  }) async {
    try {
      await remoteDataSource.createOrder(
        cartItems: cartItems,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        shippingLatitude: shippingLatitude,
        shippingLongitude: shippingLongitude,
        notes: notes,
      );
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Orden>>> getUserOrders() async {
    try {
      final orderModels = await remoteDataSource.getUserOrders();
      return Right(orderModels.map<Orden>((model) => (model as dynamic).toEntity()).toList());
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Orden>> getOrderDetails(String orderId) async {
    try {
      final orderModel = await remoteDataSource.getOrderDetails(orderId);
      return Right(orderModel.toEntity());
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}