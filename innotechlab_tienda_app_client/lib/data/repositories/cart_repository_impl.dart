import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/presentation/pages/cart/cart_page.dart';

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
        // Si el producto ya está en el carrito, incrementa la cantidad
        final existingItem = updatedItems[existingItemIndex];
        updatedItems[existingItemIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
      } else {
        // Si el producto no está, añádelo
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
          updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(quantity: quantity);
        } else {
          // Si la cantidad es 0 o menos, remover el ítem
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

// Providers de Riverpod para el carrito
final cartLocalDataSourceProvider = Provider<CartLocalDataSource>((ref) {
  // Asegúrate de que SharedPreferences esté inicializado
  // Esto se puede hacer en main.dart antes de runApp y pasarlo a GetIt/Riverpod
  // O en el service locator, como se muestra más abajo.
  return CartLocalDataSourceImpl(sharedPreferences: ref.read(sharedPreferencesProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(localDataSource: ref.read(cartLocalDataSourceProvider));
});