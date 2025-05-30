import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

/// Widget que contiene los botones de acción para el AppBar de la página de inicio.
/// No es un Scaffold ni tiene su propio AppBar.
class HomeAppBarActions extends StatelessWidget {
  const HomeAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
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
          badgeContent: Text(
            5.toString(), // Este valor debería venir de un provider (e.g., cartProvider)
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
              context.go('/cart');
            },
          ),
        ),
      ],
    );
  }
}
