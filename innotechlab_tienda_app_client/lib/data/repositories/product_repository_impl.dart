import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/network/network_info.dart';
import 'package:mi_tienda/data/datasources/product_remote_datasource.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/repositories/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo; // <-- Añade NetworkInfo

  ProductRepositoryImpl({required this.remoteDataSource,
  required this.networkInfo, // <-- Requiere NetworkInfo});

  @override
  Future<Either<Failure, List<Product>>> getAllProducts()? async {
    if (await !networkInfo.isConnected()) {
      return Left(NetworkFailure('No internet connection'));
    }
    // Aquí puedes manejar la lógica de conexión a internet
    // y lanzar una excepción o un Failure si es necesario.
    try {
      final productModels = await remoteDataSource.getAllProducts();
      return Right(productModels.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (await !networkInfo.isConnected()) {
      return Left(NetworkFailure('No internet connection'));
    }
    // Aquí puedes manejar la lógica de conexión a internet
    // y lanzar una excepción o un Failure si es necesario.
    try {
      final productModel = await remoteDataSource.getProductById(id);
      return Right(productModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() {
    // TODO: implement getAllProducts
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) {
    // TODO: implement getProductById
    throw UnimplementedError();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.read(productRemoteDataSourceProvider),
  );
});
