import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_tienda/presentation/providers/home_provider.dart';
import 'package:mi_tienda/presentation/providers/cart_provider.dart';
import 'package:mi_tienda/presentation/widgets/product_card.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

// Removed: import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart'; 
// as it's not directly used in the extracted body. If homeState.isLoading implies a general loader, 
// and _buildProductGridSkeleton is the specific one, this might be fine.

class HomeTabPageContent extends ConsumerWidget {
  const HomeTabPageContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    // cartState is not directly used in the body, but onAddToCart needs cartProvider.
    // final cartState = ref.watch(cartProvider); // Keep if needed for other logic

    // This is the content previously in HomePage's Scaffold body
    if (homeState.isLoading) {
      return _buildProductGridSkeleton(context);
    }

    if (homeState.errorMessage != null) {
      return Center(child: Text(homeState.errorMessage!));
    }

    // Data loaded state: Show banner and product grid
    return Column(
      children: [
        _buildPromotionalBanner(context), // Add the promotional banner
        Expanded( // GridView needs to be expanded within a Column
          child: RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).fetchProducts(),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), // Adjust padding
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: homeState.products.length,
                  itemBuilder: (context, index) {
                    final product = homeState.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        context.go('/product/${product.id}');
                      },
                      onAddToCart: () {
                        ref.read(cartProvider.notifier).addItemToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} agregado al carrito'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
  }

  // Promotional Banner Widget
  Widget _buildPromotionalBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0), // Adjusted bottom margin
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent.shade100, // Example color from snippet
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ // Optional: add a subtle shadow
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '¡Oferta Especial!', // Updated text
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '20% de descuento en electrónicos seleccionados.', // Updated text
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16), // Add some space before the button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cupón "ELECTRO20" activado! (MVP)')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // Button background color
              foregroundColor: Colors.blueAccent.shade700, // Button text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  // Copied from HomePage: Method to build the skeleton loader
  Widget _buildProductGridSkeleton(BuildContext context) { // Added context if it's needed by Shimmer or other parts
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.7,
        ),
        itemCount: 6, // Show some skeleton items
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white, // Shimmer will animate over this
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        width: 80.0,
                        height: 12.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8.0),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
