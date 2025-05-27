import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_tienda/presentation/providers/home_provider.dart';
import 'package:mi_tienda/presentation/providers/auth_provider.dart';
import 'package:mi_tienda/presentation/providers/cart_provider.dart';
import 'package:mi_tienda/presentation/widgets/product_card.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Tienda'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  context.push('/cart');
                },
              ),
              Consumer(builder: (context, watch, child) {
                final cartState = ref.watch(cartProvider);
                if (cartState.cartItems.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartState.cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person), // Icono para el perfil
            onPressed: () {
              context.push('/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications), // Icono para notificaciones
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authNotifier.signOut();
            },
          ),
        ],
      ),
      body: homeState.isLoading
          ? const Center(child: LoadingIndicator())
          : homeState.errorMessage != null
              ? Center(child: Text('Error: ${homeState.errorMessage}'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(homeProvider.notifier).loadProducts(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
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
                          context.push('/product/${product.id}');
                        },
                        onAddToCart: () {
                          cartNotifier.addItemToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} añadido al carrito.')),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}