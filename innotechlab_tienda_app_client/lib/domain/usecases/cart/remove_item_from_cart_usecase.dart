import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';

class RemoveItemFromCartUseCase implements UseCase<List<CartItem>, RemoveFromCartParams> {
  final CartRepository repository;

  RemoveItemFromCartUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(RemoveFromCartParams params) async {
    return await repository.removeItem(params.productId);
  }
}

class RemoveFromCartParams extends Equatable {
  final String productId;
  const RemoveFromCartParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}
