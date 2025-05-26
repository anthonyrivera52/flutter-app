import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/usecases/product/get_product_by_id_usecase.dart';

final productDetailsProvider =
    StateNotifierProvider.family<ProductDetailsNotifier, AsyncValue<Product?>, String>(
  (ref, productId) {
    final getProductByIdUseCase = ref.watch(getProductByIdUseCaseProvider);
    return ProductDetailsNotifier(getProductByIdUseCase, productId);
  },
);

class ProductDetailsNotifier extends StateNotifier<AsyncValue<Product?>> {
  final GetProductByIdUseCase _getProductByIdUseCase;
  final String _productId;

  ProductDetailsNotifier(this._getProductByIdUseCase, this._productId)
      : super(const AsyncValue.loading()) {
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    state = const AsyncValue.loading();
    final result = await _getProductByIdUseCase(GetProductByIdParams(productId: _productId));
    result.fold(
      (failure) => state = AsyncValue.error(_mapFailureToMessage(failure), StackTrace.current),
      (product) => state = AsyncValue.data(product),
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