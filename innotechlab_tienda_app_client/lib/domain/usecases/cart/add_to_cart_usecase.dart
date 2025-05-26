import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';
import 'package:mi_tienda/service_locator.dart';

class AddItemToCartUseCase implements UseCase<List<CartItem>, AddItemToCartParams> {
  final CartRepository repository;

  AddItemToCartUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(AddItemToCartParams params) async {
    return await repository.addItem(params.product);
  }
}

class AddItemToCartParams {
  final Product product;
  AddItemToCartParams({required this.product});
}

final addItemToCartUseCaseProvider = Provider<AddItemToCartUseCase>((ref) {
  return AddItemToCartUseCase(ref.read(cartRepositoryProvider));
});