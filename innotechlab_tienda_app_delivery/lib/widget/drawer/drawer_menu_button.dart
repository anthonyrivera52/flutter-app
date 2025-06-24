// lib/widget/drawer/drawer_menu_button.dart
import 'package:flutter/material.dart';

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    // El AnimatedContainer y su contenido ahora son el botón de menú
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white, // O el color que desees para el botón
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black, size: 30), // Icono de menú
        onPressed: () {
          // Usa Scaffold.of(context).openDrawer() para abrir el Drawer real
          Scaffold.of(context).openDrawer();
        },
      ),
    );
  }
}