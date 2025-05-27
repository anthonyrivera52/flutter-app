import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/usecases/cart/add_item_to_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/clear_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/get_cart_items_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/remove_item_from_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/update_item_quantity_usecase.dart';
import 'package:mi_tienda/service_locator.dart';

// Estado del carrito
class CartState {
  final List<CartItem> cartItems;
  final bool isLoading;
  final String? errorMessage;

  CartState({
    this.cartItems = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CartState copyWith({
    List<CartItem>? cartItems,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      cartItems: cartItems ?? this.cartItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Proveedor del carrito
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final addItemToCartUseCase = ref.watch(addItemToCartUseCaseProvider);
  final removeItemFromCartUseCase = ref.watch(removeItemFromCartUseCaseProvider);
  final updateItemQuantityUseCase = ref.watch(updateItemQuantityUseCaseProvider);
  final getCartItemsUseCase = ref.watch(getCartItemsUseCaseProvider);
  final clearCartUseCase = ref.watch(clearCartUseCaseProvider);

  return CartNotifier(
    addItemToCartUseCase,
    removeItemFromCartUseCase,
    updateItemQuantityUseCase,
    getCartItemsUseCase,
    clearCartUseCase,
  );
});

class CartNotifier extends StateNotifier<CartState> {
  final AddItemToCartUseCase _addItemToCartUseCase;
  final RemoveItemFromCartUseCase _removeItemFromCartUseCase;
  final UpdateItemQuantityUseCase _updateItemQuantityUseCase;
  final GetCartItemsUseCase _getCartItemsUseCase;
  final ClearCartUseCase _clearCartUseCase;

  CartNotifier(
    this._addItemToCartUseCase,
    this._removeItemFromCartUseCase,
    this._updateItemQuantityUseCase,
    this._getCartItemsUseCase,
    this._clearCartUseCase,
  ) : super(CartState()) {
    loadCartItems();
  }

  Future<void> loadCartItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _getCartItemsUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> addItemToCart(Product product) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _addItemToCartUseCase(AddToCartParams(product: product));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> removeItemFromCart(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _removeItemFromCartUseCase(RemoveFromCartParams(productId: productId));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> updateItemQuantity(String productId, int quantity) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _updateItemQuantityUseCase(UpdateItemQuantityParams(productId: productId, quantity: quantity));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> clearCart() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _clearCartUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (_) => state = state.copyWith(isLoading: false, cartItems: []),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}
