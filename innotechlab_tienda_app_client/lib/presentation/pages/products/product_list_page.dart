import 'package:flutter/material.dart';
import 'package:flutter_app/config/mock/app_mock.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/presentation/widget/product/product_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Página que muestra una lista de productos filtrados por categoría o tipo.
class ProductListPage extends ConsumerWidget {
  final String categoryId;
  final String categoryName;

  const ProductListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Product> productsToShow;

    if (categoryId == MockData.discountedProductsCategoryId) {
      // Si la categoría es "Discounted Products", mostrar todos los productos con descuento
      productsToShow = MockData.mockProducts.where((p) => p.discountedPrice != null).toList();
    } else if (categoryId == MockData.allProductsCategoryId) {
      // Si la categoría es "All Products", mostrar todos los productos
      productsToShow = MockData.mockProducts;
    } else {
      // Si es una categoría normal, filtrar por categoryId
      productsToShow = MockData.mockProducts
          .where((product) => product.categoryId == categoryId) // CAMBIADO: Usar product.categoryId
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName), // Título del AppBar con el nombre de la categoría
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // GoRouter maneja el pop de la pila de navegación
          },
        ),
      ),
      body: productsToShow.isEmpty
          ? Center(
              child: Text('No hay productos en la categoría "$categoryName".'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.7,
              ),
              itemCount: productsToShow.length,
              itemBuilder: (context, index) {
                final product = productsToShow[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    context.go('/product/${product.id}'); // Navegar al detalle del producto
                  },
                  onAddToCart: () {
                    // ref.read(cartProvider.notifier).addItemToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} agregado al carrito'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}