import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';
import 'package:mi_tienda/service_locator.dart';

class UpdateItemQuantityUseCase implements UseCase<List<CartItem>, UpdateItemQuantityParams> {
  final CartRepository repository;

  UpdateItemQuantityUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(UpdateItemQuantityParams params) async {
    return await repository.updateItemQuantity(params.productId, params.quantity);
  }
}

class UpdateItemQuantityParams {
  final String productId;
  final int quantity;
  UpdateItemQuantityParams({required this.productId, required this.quantity});
}

final updateItemQuantityUseCaseProvider = Provider<UpdateItemQuantityUseCase>((ref) {
  return UpdateItemQuantityUseCase(ref.read(cartRepositoryProvider));
});