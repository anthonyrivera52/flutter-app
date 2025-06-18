import 'package:dartz/dartz.dart' hide Orden;
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/data/datasources/orden_remote_datasource.dart';
import 'package:flutter_app/data/repositories/orden_repository_impl.dart';
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class OrdenRepository {
  Future<Either<Failure, void>> placeOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String shippingAddress,
    required double shippingLatitude,
    required double shippingLongitude,
    String? notes,
  });

  Future<Either<Failure, List<Orden>>> getUserOrders();
  Future<Either<Failure, Orden>> getOrderDetails(String orderId);
}

final orderRepositoryProvider = Provider<OrdenRepository>((ref) {
  return OrdenRepositoryImpl(
    remoteDataSource: ref.read(orderRemoteDataSourceProvider),
  );
});