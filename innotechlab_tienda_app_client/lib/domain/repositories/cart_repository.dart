import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/product.dart';

abstract class CartRepository {
  Future<Either<Failure, List<CartItem>>> getCartItems();
  Future<Either<Failure, List<CartItem>>> addItem(Product product);
  Future<Either<Failure, List<CartItem>>> removeItem(String productId);
  Future<Either<Failure, List<CartItem>>> updateItemQuantity(String productId, int quantity);
  Future<Either<Failure, void>> clearCart();
}
