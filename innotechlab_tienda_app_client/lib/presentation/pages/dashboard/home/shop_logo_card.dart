import 'package:flutter/material.dart';
import 'package:flutter_app/domain/entities/shop.dart';

class ShopLogoCard extends StatelessWidget {
  final Shop shop;
  final double distanceKm;
  final bool isActive;
  final VoidCallback onTap;

  const ShopLogoCard({
    super.key,
    required this.shop,
    required this.distanceKm,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                shop.logoUrl,
                fit: BoxFit.cover,
                height: 90,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 90,
                  color: Colors.grey[300],
                  child: Icon(Icons.store, color: Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              shop.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              shop.schedule,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${distanceKm.toStringAsFixed(1)} km de distancia',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
