
// order_repository_impl.dart (Data Repository Impl)
import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/data/datasources/order_remote_datasource.dart';
import 'package:mi_tienda/data/models/order_model.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getUserOrders() async {
    try {
      final orderModels = await remoteDataSource.getUserOrders();
      return Right(orderModels.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderDetails(String orderId) async {
    try {
      final orderModel = await remoteDataSource.getOrderDetails(orderId);
      return Right(orderModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
