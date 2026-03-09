import 'package:flutter_app/config/mock/app_mock.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productDetailsProvider =
    StateNotifierProvider.family<ProductDetailsNotifier, AsyncValue<Product?>, String>(
  (ref, productId) => ProductDetailsNotifier(productId),
);

class ProductDetailsNotifier extends StateNotifier<AsyncValue<Product?>> {
  final String _productId;

  ProductDetailsNotifier(this._productId) : super(const AsyncValue.loading()) {
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    state = const AsyncValue.loading();

    final product = MockData.mockProducts.cast<Product?>().firstWhere(
          (item) => item?.id == _productId,
          orElse: () => null,
        );

    if (product == null) {
      state = AsyncValue.error(
        'No se encontró el producto solicitado.',
        StackTrace.current,
      );
      return;
    }

    state = AsyncValue.data(product);
  }
}
