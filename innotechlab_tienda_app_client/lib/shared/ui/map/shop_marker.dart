import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:latlong2/latlong.dart';

class ShopMarkerOptions {
  final double size;
  final double selectedSize;
  final Color borderColor;
  final Color selectedBorderColor;
  final double borderWidth;
  final double selectedBorderWidth;
  final Color distanceBackgroundColor;
  final Color selectedDistanceBackgroundColor;
  final Color distanceTextColor;
  final IconData fallbackIcon;
  final double iconSize;

  const ShopMarkerOptions({
    this.size = 44,
    this.selectedSize = 52,
    this.borderColor = Colors.grey,
    this.selectedBorderColor = AppColors.primaryColor,
    this.borderWidth = 2,
    this.selectedBorderWidth = 3,
    this.distanceBackgroundColor = Colors.white,
    this.selectedDistanceBackgroundColor = AppColors.primaryColor,
    this.distanceTextColor = Colors.black87,
    this.fallbackIcon = Icons.store,
    this.iconSize = 22,
  });

  ShopMarkerOptions copyWith({
    double? size,
    double? selectedSize,
    Color? borderColor,
    Color? selectedBorderColor,
    double? borderWidth,
    double? selectedBorderWidth,
    Color? distanceBackgroundColor,
    Color? selectedDistanceBackgroundColor,
    Color? distanceTextColor,
    IconData? fallbackIcon,
    double? iconSize,
  }) {
    return ShopMarkerOptions(
      size: size ?? this.size,
      selectedSize: selectedSize ?? this.selectedSize,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      distanceBackgroundColor:
          distanceBackgroundColor ?? this.distanceBackgroundColor,
      selectedDistanceBackgroundColor:
          selectedDistanceBackgroundColor ??
          this.selectedDistanceBackgroundColor,
      distanceTextColor: distanceTextColor ?? this.distanceTextColor,
      fallbackIcon: fallbackIcon ?? this.fallbackIcon,
      iconSize: iconSize ?? this.iconSize,
    );
  }
}

class ShopMarkerData {
  final String id;
  final String name;
  final String? logoUrl;
  final String? address;
  final LatLng position;
  final double? distanceKm;
  final bool isOpen;
  final String? statusText;
  final Map<String, dynamic>? customData;

  const ShopMarkerData({
    required this.id,
    required this.name,
    this.logoUrl,
    this.address,
    required this.position,
    this.distanceKm,
    this.isOpen = false,
    this.statusText,
    this.customData,
  });
}

class ShopMarker extends StatelessWidget {
  final ShopMarkerData shop;
  final bool isSelected;
  final ShopMarkerOptions options;
  final VoidCallback? onTap;
  final bool showDistance;

  const ShopMarker({
    super.key,
    required this.shop,
    this.isSelected = false,
    this.options = const ShopMarkerOptions(),
    this.onTap,
    this.showDistance = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentSize = isSelected ? options.selectedSize : options.size;
    final currentBorderColor = isSelected
        ? options.selectedBorderColor
        : options.borderColor;
    final currentBorderWidth = isSelected
        ? options.selectedBorderWidth
        : options.borderWidth;
    final currentDistanceBgColor = isSelected
        ? options.selectedDistanceBackgroundColor
        : options.distanceBackgroundColor;
    final currentDistanceTextColor = isSelected
        ? Colors.white
        : options.distanceTextColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: currentSize,
              height: currentSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: currentBorderColor,
                  width: currentBorderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: shop.logoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: SizedBox(
                            width: options.iconSize,
                            height: options.iconSize,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          options.fallbackIcon,
                          size: options.iconSize,
                          color: Colors.grey,
                        ),
                      )
                    : Icon(
                        options.fallbackIcon,
                        size: options.iconSize,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            if (showDistance && shop.distanceKm != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: currentDistanceBgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${shop.distanceKm!.toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: currentDistanceTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AnimatedShopMarker extends StatefulWidget {
  final ShopMarkerData shop;
  final bool isSelected;
  final ShopMarkerOptions options;
  final VoidCallback? onTap;
  final bool showDistance;

  const AnimatedShopMarker({
    super.key,
    required this.shop,
    this.isSelected = false,
    this.options = const ShopMarkerOptions(),
    this.onTap,
    this.showDistance = true,
  });

  @override
  State<AnimatedShopMarker> createState() => _AnimatedShopMarkerState();
}

class _AnimatedShopMarkerState extends State<AnimatedShopMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(AnimatedShopMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSelected ? _bounceAnimation.value : 1.0,
          child: ShopMarker(
            shop: widget.shop,
            isSelected: widget.isSelected,
            options: widget.options,
            onTap: widget.onTap,
            showDistance: widget.showDistance,
          ),
        );
      },
    );
  }
}
