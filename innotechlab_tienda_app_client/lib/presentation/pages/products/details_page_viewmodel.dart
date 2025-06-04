import 'package:flutter_app/config/mock/app_mock.dart';
import 'package:flutter_app/core/errors/failures.dart'; // Ensure these are correctly defined
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Helper extension for .firstWhereOrNull (if not already part of your Dart SDK or a utility package)
// You might already have this from the previous full code provided.
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

final productDetailsProvider =
    StateNotifierProvider.family<ProductDetailsNotifier, AsyncValue<Product?>, String>(
  (ref, productId) {
    // For a mock scenario, we can directly instantiate the Notifier with the productId.
    // If you were to use a real use case, you would uncomment and provide it here.
    // final getProductByIdUseCase = ref.watch(getProductByIdUseCaseProvider);
    return ProductDetailsNotifier(productId);
  },
);

class ProductDetailsNotifier extends StateNotifier<AsyncValue<Product?>> {
  final String _productId;

  // The constructor now only takes the productId since it directly accesses MockData.
  ProductDetailsNotifier(this._productId)
      : super(const AsyncValue.loading()) {
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    state = const AsyncValue.loading();
    
    // Safely find the product using firstWhereOrNull
    final Product? product = MockData.mockProducts.firstWhereOrNull(
      (p) => p.id == _productId,
    );

    if (product == null) {
      // If product is not found, set an error state.
      // This simulates a 'Product not found' failure.
      state = AsyncValue.error('Product with ID "$_productId" not found.', StackTrace.current);
    } else {
      // If product is found, set the data state.
      state = AsyncValue.data(product);
    }
  }

  // This method remains to map potential failures, though in a pure mock setup
  // without a real API call, only the 'Product not found' error would be triggered
  // by the logic above.
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else if (failure is CacheFailure) {
      return failure.message;
    } else {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}