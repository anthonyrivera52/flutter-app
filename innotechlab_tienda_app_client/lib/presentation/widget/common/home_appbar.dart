import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/pages/cart/cart_page.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

/// Widget que contiene los botones de acción para el AppBar de la página de inicio.
/// No es un Scaffold ni tiene su propio AppBar.
class HomeAppBarActions extends ConsumerWidget {
  const HomeAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final cartState = ref.watch(cartProvider);
    return Row( // Usa un Row para contener los múltiples iconos de acción
      mainAxisSize: MainAxisSize.min, // Para que el Row ocupe solo el espacio necesario
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            context.go('/notifications');
          },
        ),
        badges.Badge(
          
          showBadge: true,
          badgeContent: cartState.cartItems.isNotEmpty
              ? Text(
                  cartState.cartItems.length.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )
              : null,
          position: badges.BadgePosition.topEnd(top: 0, end: 3),
          badgeStyle:  cartState.cartItems.isNotEmpty
            ? const badges.BadgeStyle(
              badgeColor:  Colors.red,
              padding: EdgeInsets.all(5),
            )
            :const badges.BadgeStyle(
              badgeColor: Colors.transparent,
              padding: EdgeInsets.zero,
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
      ],
    );
  }
}
