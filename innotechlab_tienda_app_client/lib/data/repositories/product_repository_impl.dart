import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/network/network_info.dart';
import 'package:mi_tienda/data/datasources/product_remote_datasource.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    if (await networkInfo.isConnected()) {
      try {
        final productModels = await remoteDataSource.getAllProducts();
        return Right(productModels.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet.'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (await networkInfo.isConnected()) {
      try {
        final productModel = await remoteDataSource.getProductById(id);
        return Right(productModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet.'));
    }
  }
}
