import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/presentation/widget/quantity_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasDiscount =
        product.discountedPrice != null &&
        product.discountedPrice! < product.price;

    final cartItems = ref.watch(cartProvider.select((s) => s.items));
    final cartItem = cartItems.where((i) => i.productId == product.id).firstOrNull;
    final quantity = cartItem?.quantity ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: AppColors.greyLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.greyLight,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${((1 - (product.discountedPrice! / product.price)) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.unit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLightColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.greyDark,
                                  ),
                            ),
                          Text(
                            '\$${(hasDiscount ? product.discountedPrice! : product.price).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      if (quantity == 0)
                        IconButton(
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: () =>
                              ref.read(cartProvider.notifier).addItem(product),
                          tooltip: 'Añadir al carrito',
                        )
                      else
                        QuantitySelector(
                          isTransparentBackground: true,
                          quantity: quantity,
                          onAdd: () => ref
                              .read(cartProvider.notifier)
                              .updateQuantity(product.id, quantity + 1),
                          onRemove: () => ref
                              .read(cartProvider.notifier)
                              .updateQuantity(product.id, quantity - 1),
                          onZeroQuantity: () => ref
                              .read(cartProvider.notifier)
                              .removeItem(product.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
