
// order_repository.dart (Domain Repository Interface)
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/data/datasources/order_remote_datasource.dart';
import 'package:mi_tienda/data/repositories/order_repository_impl.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';

abstract class OrderRepository {
  Future<Either<Failure, void>> placeOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String shippingAddress,
    required double shippingLatitude,
    required double shippingLongitude,
    String? notes,
  });

  Future<Either<Failure, List<Order>>> getUserOrders();
  Future<Either<Failure, Order>> getOrderDetails(String orderId);
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    remoteDataSource: ref.read(orderRemoteDataSourceProvider),
  );
});
