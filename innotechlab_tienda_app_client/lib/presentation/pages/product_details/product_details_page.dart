import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mi_tienda/presentation/providers/home_provider.dart'; // Contiene productDetailsProvider
import 'package:mi_tienda/presentation/providers/cart_provider.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_button.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';

class ProductDetailsPage extends ConsumerWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productDetailsProvider(productId));
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Producto'),
      ),
      body: productState.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Producto no encontrado.'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    height: 300,
                    placeholder: (context, url) => const Center(child: LoadingIndicator()),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/placeholder.png', fit: BoxFit.cover, height: 300),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textLightColor,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Añadir al Carrito',
                        onPressed: () {
                          cartNotifier.addItemToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} añadido al carrito.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar el producto: $error')),
      ),
    );
  }
}
