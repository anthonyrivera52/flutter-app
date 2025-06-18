import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/pages/cart/cart_page.dart';
import 'package:flutter_app/presentation/pages/products/details_page_viewmodel.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_app/presentation/widget/quantity_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';


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

// A new provider to manage the quantity of the *current product* on the detail page.
// This is specific to the UI state of the details page, not the cart itself.
final _currentProductQuantityProvider = StateProvider.family<int, String>((ref, productId) {
  // Check if the product is already in the cart and set initial quantity
  final cartItems = ref.watch(cartProvider.select((state) => state.cartItems));
  final existingCartItem = FirstWhereOrNullExtension(cartItems).firstWhereOrNull((item) => item.productId == productId);
  return existingCartItem?.quantity ?? 0; // If not in cart, quantity is 0
});

class ProductDetailsPage extends ConsumerWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productDetailsState = ref.watch(productDetailsProvider(productId));
    final cartState = ref.watch(cartProvider);
    final productQuantity = ref.watch(_currentProductQuantityProvider(productId));
    final productQuantityNotifier = ref.read(_currentProductQuantityProvider(productId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Producto'),
        actions: [
          badges.Badge(
            showBadge: cartState.cartItems.isNotEmpty,
            badgeContent: Text(
              cartState.cartItems.length.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            position: badges.BadgePosition.topEnd(top: 0, end: 3),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.red,
              padding: EdgeInsets.all(5),
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Allows the modal to be taller than half the screen
                  builder: (BuildContext context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.75, // Initial height of the modal (75% of screen height)
                      minChildSize: 0.5, // Minimum height
                      maxChildSize: 0.95, // Maximum height
                      expand: false, // Do not expand to full screen by default
                      builder: (BuildContext context, ScrollController scrollController) {
                        return CartModalContent(); // Your cart content
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 20), // Espacio entre los iconos
        ],
      ),
      body: productDetailsState.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Producto no encontrado.'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'product_image_${product.id}',
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error, size: 50, color: Colors.red),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      // --- Conditional rendering for quantity selector or add to cart button ---
                      Row( // Use a Row to align the buttons
                        mainAxisAlignment: productQuantity == 0
                            ? MainAxisAlignment.start // Align "Add to Cart" to start
                            : MainAxisAlignment.center, // Center QuantitySelector
                        children: [
                          if (productQuantity == 0) // If quantity is 0, show "Add to Cart" button
                            Expanded( // Allow button to take full width when alone
                              child: CustomButton(
                                text: 'Agregar al Carrito',
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
                              ),
                            )
                          else // If quantity is > 0, show quantity selector
                            QuantitySelector(
                              isTransparentBackground: false,
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
                                productQuantityNotifier.state = 0; // Reset local state, will show "Add to Cart"
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} removido del carrito.'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      // --- End of conditional rendering ---
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}