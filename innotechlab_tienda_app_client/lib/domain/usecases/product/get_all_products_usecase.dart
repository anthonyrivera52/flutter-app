import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/repositories/product_repository.dart';

class GetAllProductsUseCase implements UseCase<List<Product>, NoParams> {
  final ProductRepository repository;

  GetAllProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getAllProducts();
  }
}
