import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/pages/checkout/checkout_page.dart';
import 'package:flutter_app/presentation/provider/checkout_provider.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart';
import 'package:flutter_app/presentation/widget/cart_item_card.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartModalContent extends ConsumerWidget {
  const CartModalContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);

    final subtotal = checkoutNotifier.subtotal(cartState.cartItems);
    final total = checkoutNotifier.total(cartState.cartItems);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Mi carrito',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (cartState.isLoading)
            const Expanded(child: Center(child: LoadingIndicator()))
          else if (cartState.errorMessage != null)
            Expanded(
              child: Center(child: Text('Error: ${cartState.errorMessage}')),
            )
          else if (cartState.cartItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Tu carrito está vacío.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLightColor,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: cartState.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartState.cartItems[index];
                  return CartItemCard(
                    item: item,
                    onRemove: () =>
                        cartNotifier.removeItemFromCart(item.productId),
                    onAddQuantity: () => cartNotifier.updateItemQuantity(
                      item.productId,
                      item.quantity + 1,
                    ),
                    onDecreaseQuantity: () {
                      if (item.quantity > 1) {
                        cartNotifier.updateItemQuantity(
                          item.productId,
                          item.quantity - 1,
                        );
                      } else {
                        cartNotifier.removeItemFromCart(item.productId);
                      }
                    },
                  );
                },
              ),
            ),
          if (cartState.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Subtotal',
                    value: '\$${subtotal.toStringAsFixed(2)}',
                  ),
                  _SummaryRow(
                    label: 'Envío',
                    value: '\$${checkoutDeliveryFee.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 18),
                  _SummaryRow(
                    label: 'Total',
                    value: '\$${total.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Ir al checkout',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.9,
                            minChildSize: 0.75,
                            maxChildSize: 0.95,
                            expand: false,
                            builder: (_, __) => const CheckoutPageModal(),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Vaciar carrito'),
                          content: const Text(
                            '¿Seguro que quieres vaciar el carrito?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                cartNotifier.clearCart();
                                Navigator.of(ctx).pop();
                              },
                              child: const Text(
                                'Vaciar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Vaciar carrito',
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
