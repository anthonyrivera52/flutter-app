import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/product_detail_viewmodel.dart';
import 'package:flutter_app/presentation/pages/cart/cart_page.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_app/presentation/widget/quantity_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _productQuantityProvider = Provider.family<int, String>((ref, productId) {
  final items = ref.watch(cartProvider).items;
  final inCart = items.cast<dynamic>().firstWhere(
    (item) => item.productId == productId,
    orElse: () => null,
  );
  return inCart?.quantity ?? 0;
});

class ProductDetailsPage extends ConsumerWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsState = ref.watch(productDetailsProvider(productId));
    final cartState = ref.watch(cartProvider);
    final qty = ref.watch(_productQuantityProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Producto'),
        actions: [
          badges.Badge(
            showBadge: cartState.items.isNotEmpty,
            badgeContent: Text(
              cartState.totalQuantity.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            position: badges.BadgePosition.topEnd(top: 0, end: 2),
            badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DraggableScrollableSheet(
                    initialChildSize: 0.75,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (_, __) => CartModalContent(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: detailsState.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Producto no encontrado.'));
          }

          final hasDiscount =
              product.discountedPrice != null &&
              product.discountedPrice! < product.price;
          final displayPrice = hasDiscount
              ? product.discountedPrice!
              : product.price;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Hero(
                tag: 'product_image_${product.id}',
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.greyLight),
                  errorWidget: (_, __, ___) => Container(
                    height: 300,
                    color: AppColors.greyLight,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.unit,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.greyDark,
                                  ),
                            ),
                          ),
                        Text(
                          '\$${displayPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.secondaryDarkColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    if (qty == 0)
                      CustomButton(
                        text: 'Agregar al carrito',
                        onPressed: () {
                          ref.read(cartProvider.notifier).addItem(product);
                        },
                      )
                    else
                      Row(
                        children: [
                          QuantitySelector(
                            isTransparentBackground: false,
                            quantity: qty,
                            onAdd: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(product.id, qty + 1);
                            },
                            onRemove: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(product.id, qty - 1);
                            },
                            onZeroQuantity: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .removeItem(product.id);
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Ir al carrito',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => DraggableScrollableSheet(
                                    initialChildSize: 0.75,
                                    minChildSize: 0.5,
                                    maxChildSize: 0.95,
                                    expand: false,
                                    builder: (_, __) => CartModalContent(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
