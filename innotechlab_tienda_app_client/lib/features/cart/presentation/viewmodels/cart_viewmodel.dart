import 'package:flutter_app/features/cart/domain/models/cart_item_entity.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  CartState copyWith({List<CartItem>? items}) =>
      CartState(items: items ?? this.items);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Product product) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.productId == product.id);

    if (idx != -1) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(CartItem(
        productId: product.id,
        name: product.name,
        imageUrl: product.imageUrl,
        price: product.discountedPrice ?? product.price,
        unit: product.unit,
        quantity: 1,
      ));
    }
    state = state.copyWith(items: items);
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = state.copyWith(
      items: state.items
          .map((i) =>
              i.productId == productId ? i.copyWith(quantity: quantity) : i)
          .toList(),
    );
  }

  void clear() => state = const CartState();
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());

/// Derived provider: número de items en el carrito (para badge)
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalQuantity;
});
