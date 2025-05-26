
// place_order_usecase.dart (Domain Use Case)
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/repositories/order_repository.dart';

class PlaceOrderUseCase implements UseCase<void, PlaceOrderParams> {
  final OrderRepository repository;
  PlaceOrderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PlaceOrderParams params) async {
    return await repository.placeOrder(
      cartItems: params.cartItems,
      totalAmount: params.totalAmount,
      shippingAddress: params.shippingAddress,
      shippingLatitude: params.shippingLatitude,
      shippingLongitude: params.shippingLongitude,
      notes: params.notes,
    );
  }
}

class PlaceOrderParams {
  final List<CartItem> cartItems;
  final double totalAmount;
  final String shippingAddress;
  final double shippingLatitude;
  final double shippingLongitude;
  final String? notes;

  PlaceOrderParams({
    required this.cartItems,
    required this.totalAmount,
    required this.shippingAddress,
    required this.shippingLatitude,
    required this.shippingLongitude,
    this.notes,
  });
}

final placeOrderUseCaseProvider = Provider<PlaceOrderUseCase>((ref) {
  return PlaceOrderUseCase(ref.read(orderRepositoryProvider));
});

