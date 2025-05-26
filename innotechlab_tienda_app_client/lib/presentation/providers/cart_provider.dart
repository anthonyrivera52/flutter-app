import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/usecases/cart/add_to_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/clear_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/get_cart_items_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/remove_from_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/update_item_quantity_usecase.dart'; 

class CartState {
  final bool isLoading;
  final String? errorMessage;
  final List<CartItem> cartItems;

  CartState({
    this.isLoading = false,
    this.errorMessage,
    this.cartItems = const [],
  });

  CartState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CartItem>? cartItems,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      cartItems: cartItems ?? this.cartItems,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final addItemToCartUseCase = ref.watch(addItemToCartUseCaseProvider);
  final removeItemFromCartUseCase = ref.watch(removeItemFromCartUseCaseProvider);
  final getCartItemsUseCase = ref.watch(getCartItemsUseCaseProvider);
  final clearCartUseCase = ref.watch(clearCartUseCaseProvider);
  final updateItemQuantityUseCase = ref.watch(updateItemQuantityUseCaseProvider); // NUEVO
  
  return CartNotifier(
    addItemToCartUseCase,
    removeItemFromCartUseCase,
    updateItemQuantityUseCase, // Pásalo al constructor
    getCartItemsUseCase,
    clearCartUseCase,
  );
});

class CartNotifier extends StateNotifier<CartState> {
  final AddItemToCartUseCase _addItemToCartUseCase;
  final RemoveItemFromCartUseCase _removeItemFromCartUseCase;
  final UpdateItemQuantityUseCase _updateItemQuantityUseCase; // NUEVO
  final GetCartItemsUseCase _getCartItemsUseCase;
  final ClearCartUseCase _clearCartUseCase;

  CartNotifier(
    this._addItemToCartUseCase,
    this._removeItemFromCartUseCase,
    this._updateItemQuantityUseCase, // Recíbelo
    this._getCartItemsUseCase,
    this._clearCartUseCase,
  ) : super(CartState()) {
    loadCartItems();
  }

  Future<void> updateItemQuantity(String productId, int quantity) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _updateItemQuantityUseCase(UpdateItemQuantityParams(productId: productId, quantity: quantity));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> loadCartItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _getCartItemsUseCase(NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> addItemToCart(Product product) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _addItemToCartUseCase(AddItemToCartParams(product: product));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> removeItemFromCart(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _removeItemFromCartUseCase(RemoveItemFromCartParams(productId: productId));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> clearCart() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _clearCartUseCase(NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (_) => state = state.copyWith(isLoading: false, cartItems: []),
    );
  }
  
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) { // <-- Maneja NetworkFailure
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else if (failure is CacheFailure) {
      return failure.message;
    } else {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}