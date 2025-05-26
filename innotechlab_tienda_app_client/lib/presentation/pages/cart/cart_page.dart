
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/presentation/providers/cart_provider.dart';
import 'package:mi_tienda/presentation/widgets/cart_item_card.dart'; // Importa el CartItemCard
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_button.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    double totalAmount = cartState.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
      ),
      body: cartState.isLoading
          ? const Center(child: LoadingIndicator())
          : cartState.errorMessage != null
              ? Center(child: Text('Error: ${cartState.errorMessage}'))
              : Column(
                  children: [
                    Expanded(
                      child: cartState.cartItems.isEmpty
                          ? const Center(
                              child: Text(
                                'Tu carrito está vacío.',
                                style: TextStyle(fontSize: 18, color: AppColors.textLightColor),
                              ),
                            )
                          : ListView.builder(
                              itemCount: cartState.cartItems.length,
                              itemBuilder: (context, index) {
                                final item = cartState.cartItems[index];
                                return CartItemCard(
                                  item: item,
                                  onRemove: () {
                                    cartNotifier.removeItemFromCart(item.product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${item.product.name} removido del carrito.')),
                                    );
                                  },
                                  onAddQuantity: () {
                                    cartNotifier.updateItemQuantity(item.product.id, item.quantity + 1);
                                  },
                                  onDecreaseQuantity: () {
                                    if (item.quantity > 1) {
                                      cartNotifier.updateItemQuantity(item.product.id, item.quantity - 1);
                                    } else {
                                      // Opcional: remover directamente si la cantidad llega a 0
                                      cartNotifier.removeItemFromCart(item.product.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${item.product.name} removido del carrito.')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                    if (cartState.cartItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textColor,
                                      ),
                                ),
                                Text(
                                  '\$${totalAmount.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryColor,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Proceder al Pago',
                              onPressed: () {
                                // Aquí puedes navegar a la pantalla de pago
                                // o iniciar el proceso de checkout
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Funcionalidad de pago aún no implementada.')),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Vaciar Carrito'),
                                    content: const Text('¿Estás seguro de que quieres vaciar tu carrito?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          cartNotifier.clearCart();
                                          Navigator.of(ctx).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Carrito vaciado.')),
                                          );
                                        },
                                        child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Vaciar Carrito',
                                style: TextStyle(color: AppColors.greyDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

// Extensión para calcular el precio total de un CartItem
extension CartItemTotalPrice on CartItem {
  double get totalPrice => product.price * quantity;
}