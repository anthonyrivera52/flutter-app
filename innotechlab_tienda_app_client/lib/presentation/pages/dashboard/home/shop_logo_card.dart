import 'package:flutter/material.dart';
import 'package:flutter_app/domain/entities/shopt.dart';

class ShopLogoCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;

  const ShopLogoCard({
    super.key,
    required this.shop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // Ancho fijo para los logos de tienda
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            shop.logoUrl,
            fit: BoxFit.contain, // Ajusta la imagen dentro de la caja
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: Icon(Icons.store, color: Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }
}
