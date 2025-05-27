import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onAddQuantity;
  final VoidCallback onDecreaseQuantity;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onAddQuantity,
    required this.onDecreaseQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.greyLight,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
                ),
                errorWidget: (context, url, error) =>
                    Image.asset('assets/images/placeholder.png', width: 80, height: 80, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textLightColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.greyDark),
                            onPressed: onDecreaseQuantity,
                          ),
                          Text(
                            '${item.quantity}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
                            onPressed: onAddQuantity,
                          ),
                        ],
                      ),
                      Text(
                        '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.errorColor),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
