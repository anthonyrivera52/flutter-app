import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart';
import 'package:mi_tienda/data/models/cart_item_model.dart';
import 'package:mi_tienda/service_locator.dart';

class CartRepositoryImpl implements CartRepository {
  final CartLocalDataSource localDataSource;

  CartRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<CartItem>>> getCartItems() async {
    try {
      final result = await localDataSource.getCartItems();
      return Right(result.toEntities());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> addItem(Product product) async {
    try {
      final currentItems = await localDataSource.getCartItems();
      List<CartItemModel> updatedItems = List.from(currentItems);

      final existingItemIndex = updatedItems.indexWhere((item) => item.product.id == product.id);

      if (existingItemIndex != -1) {
        final existingItem = updatedItems[existingItemIndex];
        updatedItems[existingItemIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1) as CartItemModel;
      } else {
        updatedItems.add(CartItemModel.fromEntity(CartItem(product: product, quantity: 1)));
      }

      await localDataSource.saveCartItems(updatedItems);
      return Right(updatedItems.toEntities());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> removeItem(String productId) async {
    try {
      final currentItems = await localDataSource.getCartItems();
      List<CartItemModel> updatedItems = List.from(currentItems);

      updatedItems.removeWhere((item) => item.product.id == productId);

      await localDataSource.saveCartItems(updatedItems);
      return Right(updatedItems.toEntities());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> updateItemQuantity(String productId, int quantity) async {
    try {
      final currentItems = await localDataSource.getCartItems();
      List<CartItemModel> updatedItems = List.from(currentItems);

      final itemIndex = updatedItems.indexWhere((item) => item.product.id == productId);

      if (itemIndex != -1) {
        if (quantity > 0) {
          updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(quantity: quantity) as CartItemModel;
        } else {
          updatedItems.removeAt(itemIndex);
        }
      }

      await localDataSource.saveCartItems(updatedItems);
      return Right(updatedItems.toEntities());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearCart() async {
    try {
      await localDataSource.clearCart();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
