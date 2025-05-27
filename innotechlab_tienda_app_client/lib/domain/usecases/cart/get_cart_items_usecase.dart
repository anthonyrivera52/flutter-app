import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';

class GetCartItemsUseCase implements UseCase<List<CartItem>, NoParams> {
  final CartRepository repository;

  GetCartItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(NoParams params) async {
    return await repository.getCartItems();
  }
}
