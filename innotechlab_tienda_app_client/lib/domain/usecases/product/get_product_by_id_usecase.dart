import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/repositories/product_repository.dart';

class GetProductByIdUseCase implements UseCase<Product, GetProductByIdParams> {
  final ProductRepository repository;

  GetProductByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Product>> call(GetProductByIdParams params) async {
    return await repository.getProductById(params.id);
  }
}

class GetProductByIdParams extends Equatable {
  final String id;
  const GetProductByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}
