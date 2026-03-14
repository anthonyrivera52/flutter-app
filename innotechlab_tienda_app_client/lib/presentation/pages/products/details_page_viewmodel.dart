import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final productDetailsProvider =
    StateNotifierProvider.family<
      ProductDetailsNotifier,
      AsyncValue<Product?>,
      String
    >((ref, productId) => ProductDetailsNotifier(productId));

class ProductDetailsNotifier extends StateNotifier<AsyncValue<Product?>> {
  final String _productId;

  ProductDetailsNotifier(this._productId) : super(const AsyncValue.loading()) {
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    state = const AsyncValue.loading();

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('products')
          .select()
          .eq('id', _productId)
          .eq('is_active', true)
          .eq('is_available', true)
          .maybeSingle();

      if (response == null) {
        state = AsyncValue.error(
          'No se encontró el producto solicitado.',
          StackTrace.current,
        );
        return;
      }

      final product = Product(
        id: response['id'] as String,
        name: response['name'] as String,
        description: response['description'] as String,
        price: (response['price'] as num).toDouble(),
        imageUrl: response['image_url'] as String,
        categoryId: response['category_id'] as String,
        unit: response['unit'] as String,
        discountedPrice: response['discounted_price'] != null
            ? (response['discounted_price'] as num).toDouble()
            : null,
      );

      state = AsyncValue.data(product);
    } catch (e, st) {
      state = AsyncValue.error(
        'Error al cargar el producto: ${e.toString()}',
        st,
      );
    }
  }
}
