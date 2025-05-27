import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';

class AddItemToCartUseCase implements UseCase<List<CartItem>, AddToCartParams> {
  final CartRepository repository;

  AddItemToCartUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(AddToCartParams params) async {
    return await repository.addItem(params.product);
  }
}

class AddToCartParams extends Equatable {
  final Product product;
  const AddToCartParams({required this.product});

  @override
  List<Object?> get props => [product];
}
