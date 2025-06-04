// lib/presentation/widget/cart/cart_modal_content.dart
// Or append this to your cart_page.dart file

import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart'; // Ensure this path is correct
import 'package:flutter_app/domain/entities/cartItem.dart'; // Ensure this path is correct
import 'package:flutter_app/presentation/provider/cart_provider.dart'; // Ensure this path is correct
import 'package:flutter_app/presentation/widget/cart_item_card.dart'; // Ensure this path is correct
import 'package:flutter_app/presentation/widget/common/custom_button.dart'; // Ensure this path is correct
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart'; // Ensure this path is correct
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartModalContent extends ConsumerWidget {
  const CartModalContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    double totalAmount = cartState.cartItems.fold(0.0, (sum, item) => 
      sum + item.totalPrice);

    return Container(
      // Optional: Add some padding or shape for the modal
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor, // Use canvasColor for modal background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make the column take minimum vertical space
        children: [
          // Optional: A drag handle for the modal
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(bottom: 16.0),
          ),
          Text(
            'Mi Carrito',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (cartState.isLoading)
            const Expanded(child: Center(child: LoadingIndicator()))
          else if (cartState.errorMessage != null)
            Expanded(child: Center(child: Text('Error: ${cartState.errorMessage}')))
          else if (cartState.cartItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Tu carrito está vacío.',
                  style: TextStyle(fontSize: 18, color: AppColors.textLightColor),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true, // Important for ListView inside Column
                itemCount: cartState.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartState.cartItems[index];
                  return CartItemCard(
                    item: item,
                    onRemove: () {
                      cartNotifier.removeItemFromCart(item.productId);
                      // Navigator.of(context).pop(); // Consider if you want to close modal on remove
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} removido del carrito.')),
                      );
                    },
                    onAddQuantity: () {
                      cartNotifier.updateItemQuantity(item.productId, item.quantity + 1);
                    },
                    onDecreaseQuantity: () {
                      if (item.quantity > 1) {
                        cartNotifier.updateItemQuantity(item.productId, item.quantity - 1);
                      } else {
                        cartNotifier.removeItemFromCart(item.productId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.name} removido del carrito.')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          if (cartState.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0), // Add padding above the summary
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
                      Navigator.of(context).pop(); // Close the modal
                      // You can then navigate to a payment page or trigger checkout
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidad de pago aún no implementada.')),
                      );
                      // If you have a specific payment route
                      // context.go('/checkout'); // Example using GoRouter
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
                                Navigator.of(ctx).pop(); // Close the confirmation dialog
                                // You might want to keep the modal open or close it
                                // Navigator.of(context).pop(); // Close the cart modal too
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

// Extensión para calcular el precio total de un CartItem (keep this in the same file as CartItem definition or separate utility)
extension CartItemTotalPrice on CartItem {
  double get totalPrice => price * quantity;
}