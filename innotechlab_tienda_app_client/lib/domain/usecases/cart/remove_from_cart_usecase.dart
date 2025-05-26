import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';
import 'package:mi_tienda/service_locator.dart';

class RemoveItemFromCartUseCase implements UseCase<List<CartItem>, RemoveItemFromCartParams> {
  final CartRepository repository;

  RemoveItemFromCartUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(RemoveItemFromCartParams params) async {
    return await repository.removeItem(params.productId);
  }
}

class RemoveItemFromCartParams {
  final String productId;
  RemoveItemFromCartParams({required this.productId});
}

final removeItemFromCartUseCaseProvider = Provider<RemoveItemFromCartUseCase>((ref) {
  return RemoveItemFromCartUseCase(ref.read(cartRepositoryProvider));
});