import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart'; // Ensure this path is correct
import 'package:flutter_app/domain/entities/cartItem.dart'; // Ensure this path is correct
import 'package:flutter_app/presentation/pages/checkout/checkout_page.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart'; // Ensure this path is correct
import 'package:flutter_app/presentation/widget/cart_item_card.dart'; // Ensure this path is correct
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart'; // Ensure this path is correct
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:slide_action/slide_action.dart';

class CartModalContent extends ConsumerWidget {
  const CartModalContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final double shippingAmount = 200.00; // Puedes hacer esto dinámico si es necesario
    final double minimumAmountForFreeShipping = 210.00; // Monto mínimo para envío gratis
    double subtotalAmount = cartState.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final double grandTotal = subtotalAmount + shippingAmount; // El valor total a pagar

    // Define si el slide action debe estar habilitado o no
    final bool isSlideActionEnabled = grandTotal >= minimumAmountForFreeShipping;

    // Define el onPressed para el SlideAction, será null si está deshabilitado
    VoidCallback? slideActionOnSlide() {
      if (isSlideActionEnabled) {
        return () {
          // Lógica a ejecutar cuando se desliza el SlideAction (por ejemplo, ir a la pantalla de pago)
          // Navigator.of(context).pop(); // Cierra el modal
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Pago iniciado por deslizamiento. Total: \$${grandTotal.toStringAsFixed(2)}')),
          // );
          
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
                  return CheckoutPageModal(); // Your cart content
                },
              );
            },
          );
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => CheckoutPageModal()
          //   )
          // );
        };
      }
      return null; // Si es null, el SlideAction estará deshabilitado
    }

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
                shrinkWrap: true,
                itemCount: cartState.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartState.cartItems[index];
                  return CartItemCard(
                    item: item,
                    onRemove: () {
                      cartNotifier.removeItemFromCart(item.productId);
                    },
                    onAddQuantity: () {
                      cartNotifier.updateItemQuantity(item.productId, item.quantity + 1);
                    },
                    onDecreaseQuantity: () {
                      if (item.quantity > 1) {
                        cartNotifier.updateItemQuantity(item.productId, item.quantity - 1);
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
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Envío:',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                      ),
                      Text(
                        '\$${shippingAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppColors.primaryColor,
                            ),
                      ),
                    ],
                  ),
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
                        '\$${grandTotal.toStringAsFixed(2)}', // Usa el grandTotal calculado
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SlideAction(
                      trackBuilder: (context, state) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isSlideActionEnabled ? AppColors.backgroundColor : AppColors.greyLight, // Color del fondo del track
                            boxShadow: isSlideActionEnabled
                                ? const [BoxShadow(color: Colors.black26, blurRadius: 8)]
                                : null, // Sin sombra si está deshabilitado
                          ),
                          child: Center(
                            child: Text(
                              isSlideActionEnabled ? "Desliza para pagar" : "Pago mínimo \$${minimumAmountForFreeShipping.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isSlideActionEnabled ? AppColors.primaryColor : AppColors.greyDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      thumbBuilder: (context, state) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSlideActionEnabled ? AppColors.primaryColor : AppColors.greyDark, // Color del pulgar
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.chevron_right,
                              color: isSlideActionEnabled ? AppColors.backgroundColor : AppColors.textLightColor, // Color del icono
                            ),
                          ),
                        );
                      },
                      action: slideActionOnSlide(), // Aquí se pasa la acción o null
                    ),
                  ),
                  const SizedBox(height: 16), // Espacio entre el SlideAction y el CustomButton
                  // CustomButton(
                  //   // El CustomButton se puede mantener o eliminar si solo quieres el SlideAction
                  //   backgroundColor: isSlideActionEnabled ? AppColors.primaryColor : AppColors.greyLight,
                  //   foregroundColor: isSlideActionEnabled ? AppColors.backgroundColor : AppColors.textLightColor,
                  //   isLoading: cartState.isLoading,
                  //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  //   fontSize: 16,
                  //   fontWeight: FontWeight.bold,
                  //   borderRadius: 10.0,
                  //   text: 'Proceder al Pago',
                  //   onPressed: () => isSlideActionEnabled
                  //       ? () {
                  //           Navigator.of(context).pop(); // Cierra el modal
                  //           ScaffoldMessenger.of(context).showSnackBar(
                  //             SnackBar(content: Text('Pago iniciado por botón. Total: \$${grandTotal.toStringAsFixed(2)}')),
                  //           );
                  //           // context.go('/checkout'); // Ejemplo con GoRouter
                  //         }
                  //       : null, // Si es null, el botón estará deshabilitado
                  // ),
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