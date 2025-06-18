import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart'; // Import cart_provider
import 'package:flutter_app/presentation/widget/quantity_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import flutter_riverpod

// Helper extension for .firstWhereOrNull (if not already part of your Dart SDK or a utility package)
// Add this if you don't have it globally available, e.g., in a utils file.
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// A new provider to manage the quantity of a specific product on a ProductCard.
final _productCardQuantityProvider = StateProvider.family<int, String>((ref, productId) {
  final cartItems = ref.watch(cartProvider.select((state) => state.cartItems));
  final existingCartItem = cartItems.firstWhereOrNull((item) => item.productId == productId);
  return existingCartItem?.quantity ?? 0;
});

class ProductCard extends ConsumerWidget { // Changed to ConsumerWidget
  final Product product;
  final VoidCallback onTap;
  // final VoidCallback onAddToCart; // This is no longer needed as logic is internal

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    // required this.onAddToCart, // Remove from constructor
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Added WidgetRef ref
    final bool hasDiscount = product.discountedPrice != null && product.discountedPrice! < product.price;
    final productQuantity = ref.watch(_productCardQuantityProvider(product.id));
    final productQuantityNotifier = ref.read(_productCardQuantityProvider(product.id).notifier);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: AppColors.greyLight,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
                      ),
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/images/placeholder.png', fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${((1 - (product.discountedPrice! / product.price)) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.unit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLightColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.greyDark,
                                  ),
                            ),
                          Text(
                            '\$${(hasDiscount ? product.discountedPrice! : product.price).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      // --- Conditional rendering for quantity selector or add to cart icon ---
                      if (productQuantity == 0) // If quantity is 0, show "Add to Cart" icon
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: AppColors.primaryColor),
                          onPressed: () {
                            ref.read(cartProvider.notifier).addItemToCart(product);
                            productQuantityNotifier.state = 1; // Update local state to 1
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(
                            //     content: Text('${product.name} agregado al carrito'),
                            //     duration: const Duration(seconds: 1),
                            //   ),
                            // );
                          },
                          tooltip: 'Añadir al carrito',
                        )
                      else // If quantity is > 0, show quantity selector
                        QuantitySelector(
                          isTransparentBackground: true,
                          quantity: productQuantity,
                          onAdd: () {
                            ref.read(cartProvider.notifier).updateItemQuantity(product.id, productQuantity + 1);
                            productQuantityNotifier.state++; // Update local state
                          },
                          onRemove: () {
                            ref.read(cartProvider.notifier).updateItemQuantity(product.id, productQuantity - 1);
                            productQuantityNotifier.state--; // Update local state
                          },
                          onZeroQuantity: () {
                            // This is called when quantity drops from 1 to 0
                            ref.read(cartProvider.notifier).removeItemFromCart(product.id);
                            productQuantityNotifier.state = 0; // Reset local state, will show "Add to Cart" icon
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(
                            //     content: Text('${product.name} removido del carrito.'),
                            //     duration: const Duration(seconds: 1),
                            //   ),
                            // );
                          },
                        ),
                      // --- End of conditional rendering ---
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}