import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';

class UpdateItemQuantityUseCase implements UseCase<List<CartItem>, UpdateItemQuantityParams> {
  final CartRepository repository;

  UpdateItemQuantityUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(UpdateItemQuantityParams params) async {
    return await repository.updateItemQuantity(params.productId, params.quantity);
  }
}

class UpdateItemQuantityParams extends Equatable {
  final String productId;
  final int quantity;
  UpdateItemQuantityParams({required this.productId, required this.quantity});

  @override
  List<Object?> get props => [productId, quantity];
}
