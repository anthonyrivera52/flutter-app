
// place_order_usecase.dart (Domain Use Case)
import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/repositories/orden_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceOrderUseCase implements UseCase<void, PlaceOrderParams> {
  final OrdenRepository repository;
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