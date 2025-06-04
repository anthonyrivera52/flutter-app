import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/core/usecases/usecase.dart'; // Ensure UseCase and NoParams are defined here
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/entities/product.dart'; // Corrected from .h to .dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mi_tienda/service_locator.dart'; // Comment out or remove this if you only want mocks

// Import for MockData and Either (from dartz)
import 'package:flutter_app/config/mock/app_mock.dart'; // Assuming MockData is here
import 'package:dartz/dartz.dart'; // Needed for Either

// --- Define your UseCase abstract classes and Params if they are not already defined ---
// Assuming these are in your 'mi_tienda/domain/usecases/cart/' directory or similar.
// I'm re-adding them here for completeness of this single file, but in a real project,
// you'd import them from their respective files.

// domain/usecases/cart/add_item_to_cart_usecase.dart
abstract class AddItemToCartUseCase extends UseCase<List<CartItem>, AddToCartParams> {}
class AddToCartParams {
  final Product product;
  AddToCartParams({required this.product});
}

// domain/usecases/cart/remove_item_from_cart_usecase.dart
abstract class RemoveItemFromCartUseCase extends UseCase<List<CartItem>, RemoveFromCartParams> {}
class RemoveFromCartParams {
  final String productId;
  RemoveFromCartParams({required this.productId});
}

// domain/usecases/cart/update_item_quantity_usecase.dart
abstract class UpdateItemQuantityUseCase extends UseCase<List<CartItem>, UpdateItemQuantityParams> {}
class UpdateItemQuantityParams {
  final String productId;
  final int quantity;
  UpdateItemQuantityParams({required this.productId, required this.quantity});
}

// domain/usecases/cart/get_cart_items_usecase.dart
abstract class GetCartItemsUseCase extends UseCase<List<CartItem>, NoParams> {}

// domain/usecases/cart/clear_cart_usecase.dart
abstract class ClearCartUseCase extends UseCase<void, NoParams> {}

// --- End of UseCase abstract classes definitions ---


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

// --- NEW CODE: Mock Use Case Implementations ---

// This will hold the in-memory mock cart data
// It's initialized with a copy of MockData.mockCartItems
final List<CartItem> _inMemoryMockCart = List.from(MockData.mockCartItems);

// Mock AddItemToCartUseCase
class MockAddItemToCartUseCase implements AddItemToCartUseCase {
  @override
  Future<Either<Failure, List<CartItem>>> call(AddToCartParams params) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    final product = params.product; // Access product from params
    final existingItemIndex = _inMemoryMockCart.indexWhere((item) => item.productId == product.id);

    if (existingItemIndex != -1) {
      final existingItem = _inMemoryMockCart[existingItemIndex];
      _inMemoryMockCart[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      _inMemoryMockCart.add(CartItem(
        productId: product.id,
        name: product.name,
        imageUrl: product.imageUrl,
        price: product.discountedPrice ?? product.price,
        unit: product.unit,
        quantity: 1,
      ));
    }
    return Right(List.from(_inMemoryMockCart)); // Return a new list to ensure immutability
  }
}

// Mock RemoveItemFromCartUseCase
class MockRemoveItemFromCartUseCase implements RemoveItemFromCartUseCase {
  @override
  Future<Either<Failure, List<CartItem>>> call(RemoveFromCartParams params) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _inMemoryMockCart.removeWhere((item) => item.productId == params.productId);
    return Right(List.from(_inMemoryMockCart));
  }
}

// Mock UpdateItemQuantityUseCase
class MockUpdateItemQuantityUseCase implements UpdateItemQuantityUseCase {
  @override
  Future<Either<Failure, List<CartItem>>> call(UpdateItemQuantityParams params) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final itemIndex = _inMemoryMockCart.indexWhere((item) => item.productId == params.productId);
    if (itemIndex != -1) {
      if (params.quantity <= 0) {
        _inMemoryMockCart.removeAt(itemIndex);
      } else {
        _inMemoryMockCart[itemIndex] = _inMemoryMockCart[itemIndex].copyWith(quantity: params.quantity);
      }
    } else {
      // For mock simplicity, if item not found for update, return current state
      // or you could introduce a specific Failure like ItemNotFoundFailure.
      // For now, it will just return the current cart items without modification.
    }
    return Right(List.from(_inMemoryMockCart));
  }
}

// Mock GetCartItemsUseCase
class MockGetCartItemsUseCase implements GetCartItemsUseCase {
  @override
  Future<Either<Failure, List<CartItem>>> call(NoParams params) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Right(List.from(_inMemoryMockCart));
  }
}

// Mock ClearCartUseCase
class MockClearCartUseCase implements ClearCartUseCase {
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _inMemoryMockCart.clear();
    return const Right(null);
  }
}

// NEW CODE: Riverpod Providers for Mock Use Cases
final mockAddItemToCartUseCaseProvider = Provider<AddItemToCartUseCase>((ref) {
  return MockAddItemToCartUseCase();
});

final mockRemoveItemFromCartUseCaseProvider = Provider<RemoveItemFromCartUseCase>((ref) {
  return MockRemoveItemFromCartUseCase();
});

final mockUpdateItemQuantityUseCaseProvider = Provider<UpdateItemQuantityUseCase>((ref) {
  return MockUpdateItemQuantityUseCase();
});

final mockGetCartItemsUseCaseProvider = Provider<GetCartItemsUseCase>((ref) {
  return MockGetCartItemsUseCase();
});

final mockClearCartUseCaseProvider = Provider<ClearCartUseCase>((ref) {
  return MockClearCartUseCase();
});

// Proveedor del carrito (MODIFIED TO USE MOCK PROVIDERS)
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  // Use the mock providers here to inject mock dependencies
  final addItemToCartUseCase = ref.watch(mockAddItemToCartUseCaseProvider);
  final removeItemFromCartUseCase = ref.watch(mockRemoveItemFromCartUseCaseProvider);
  final updateItemQuantityUseCase = ref.watch(mockUpdateItemQuantityUseCaseProvider);
  final getCartItemsUseCase = ref.watch(mockGetCartItemsUseCaseProvider);
  final clearCartUseCase = ref.watch(mockClearCartUseCaseProvider);

  return CartNotifier(
    addItemToCartUseCase,
    removeItemFromCartUseCase,
    updateItemQuantityUseCase,
    getCartItemsUseCase,
    clearCartUseCase,
  );
});

class CartNotifier extends StateNotifier<CartState> {
  // These final fields are correct as they are the interfaces.
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
    final result = await _getCartItemsUseCase(NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> addItemToCart(Product product) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // The `_addItemToCartUseCase` expects `AddToCartParams`, not `Product` directly.
    final result = await _addItemToCartUseCase(AddToCartParams(product: product));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> removeItemFromCart(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // The `_removeItemFromCartUseCase` expects `RemoveFromCartParams`, not `String` directly.
    final result = await _removeItemFromCartUseCase(RemoveFromCartParams(productId: productId));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (items) => state = state.copyWith(isLoading: false, cartItems: items),
    );
  }

  Future<void> updateItemQuantity(String productId, int quantity) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // The `_updateItemQuantityUseCase` expects `UpdateItemQuantityParams`, not `String` and `int` directly.
    final result = await _updateItemQuantityUseCase(UpdateItemQuantityParams(productId: productId, quantity: quantity));
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
    } else if (failure is CacheFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}