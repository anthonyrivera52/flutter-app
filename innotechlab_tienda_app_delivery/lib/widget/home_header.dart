// lib/widget/home_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/widget/drawer/drawer_menu_button.dart'; // ¡Cambio aquí!
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);

    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const DrawerMenuButton(), // ¡Usa el nuevo botón!
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  '\$',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                ),
                Text(
                  homeViewModel.totalEarnings.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          Container()
        ],
      ),
    );
  }
}