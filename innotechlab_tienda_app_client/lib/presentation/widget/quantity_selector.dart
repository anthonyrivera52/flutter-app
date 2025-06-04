// lib/presentation/widget/product/quantity_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart'; // Ensure this path is correct

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove; // For decreasing quantity
  final VoidCallback onZeroQuantity; // Callback when quantity becomes 0

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onZeroQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20, color: AppColors.textColor),
            constraints: BoxConstraints.tight(const Size(32, 32)), // Make button smaller
            padding: EdgeInsets.zero,
            onPressed: () {
              if (quantity > 1) {
                onRemove();
              } else {
                onZeroQuantity(); // Callback to remove item if quantity is 1 and decreased
              }
            },
          ),
          Text(
            quantity.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20, color: AppColors.primaryColor),
            constraints: BoxConstraints.tight(const Size(32, 32)), // Make button smaller
            padding: EdgeInsets.zero,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}