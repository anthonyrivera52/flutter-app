import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:latlong2/latlong.dart';

class FullMapWidget extends StatefulWidget {
  final List<ShopDistance> nearbyShops;
  final double userLatitude;
  final double userLongitude;
  final Shop? selectedShop;
  final ValueChanged<Shop> onShopSelected;

  const FullMapWidget({
    super.key,
    required this.nearbyShops,
    required this.userLatitude,
    required this.userLongitude,
    required this.selectedShop,
    required this.onShopSelected,
  });

  @override
  State<FullMapWidget> createState() => _FullMapWidgetState();
}

class _FullMapWidgetState extends State<FullMapWidget>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  bool _hasAnimated = false;
  final Map<String, AnimationController> _markerAnimations = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    for (final controller in _markerAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fitBounds() {
    if (widget.nearbyShops.isEmpty) return;

    final shopLocations = widget.nearbyShops
        .map((sd) => LatLng(sd.shop.latitude, sd.shop.longitude))
        .toList();

    if (widget.userLatitude != 0 && widget.userLongitude != 0) {
      shopLocations.add(LatLng(widget.userLatitude, widget.userLongitude));
    }

    if (shopLocations.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(shopLocations);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
    _hasAnimated = true;
  }

  void _animateToLocation(LatLng point, double zoom) {
    _mapController.move(point, zoom);
  }

  @override
  void didUpdateWidget(FullMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasAnimated && widget.nearbyShops.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nearbyShops.isEmpty) {
      return _buildEmptyState();
    }

    final userLocation = LatLng(widget.userLatitude, widget.userLongitude);
    final shopLocations = widget.nearbyShops
        .map((sd) => LatLng(sd.shop.latitude, sd.shop.longitude))
        .toList();
    final allPoints = [...shopLocations, userLocation];

    LatLngBounds? bounds;
    try {
      bounds = LatLngBounds.fromPoints(allPoints);
    } catch (_) {
      bounds = null;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCameraFit: bounds != null
            ? CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(80),
              )
            : null,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onMapReady: () {
          if (!_hasAnimated) {
            _fitBounds();
          }
        },
        onTap: (tapPosition, point) {
          _handleMapTap(point);
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.innotechlab.tienda',
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        MarkerLayer(
          markers: [
            if (widget.userLatitude != 0 && widget.userLongitude != 0)
              Marker(
                point: userLocation,
                width: 44,
                height: 44,
                child: _UserMarker(),
              ),
            ...widget.nearbyShops.map((shopDistance) {
              final shop = shopDistance.shop;
              final isSelected = widget.selectedShop?.id == shop.id;
              return Marker(
                point: LatLng(shop.latitude, shop.longitude),
                width: isSelected ? 70 : 60,
                height: 85,
                key: ValueKey(shop.id),
                child: _ShopMarker(
                  shop: shop,
                  distanceKm: shopDistance.distanceKm,
                  isSelected: isSelected,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  void _handleMapTap(LatLng tappedPoint) {
    for (final shopDistance in widget.nearbyShops) {
      final shop = shopDistance.shop;
      final shopPoint = LatLng(shop.latitude, shop.longitude);
      final distance = _calculateDistance(tappedPoint, shopPoint);
      if (distance < 0.001) {
        _animateToLocation(shopPoint, 15);
        widget.onShopSelected(shop);
        break;
      }
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    final latDiff = (point1.latitude - point2.latitude).abs();
    final lngDiff = (point1.longitude - point2.longitude).abs();
    return latDiff + lngDiff;
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay comercios cercanos',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Activa el servicio de domicilio en tu zona',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMarker extends StatefulWidget {
  @override
  State<_UserMarker> createState() => _UserMarkerState();
}

class _UserMarkerState extends State<_UserMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 44 * _pulseAnimation.value,
              height: 44 * _pulseAnimation.value,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(
                  alpha: 0.3 / _pulseAnimation.value,
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class _ShopMarker extends StatelessWidget {
  final Shop shop;
  final double distanceKm;
  final bool isSelected;

  const _ShopMarker({
    required this.shop,
    required this.distanceKm,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 52 : 44,
            height: isSelected ? 52 : 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.grey.shade400,
                width: isSelected ? 3 : 2,
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
              child: shop.logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: shop.logoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.store,
                        size: isSelected ? 26 : 22,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(
                      Icons.store,
                      size: isSelected ? 26 : 22,
                      color: Colors.grey,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : Colors.white,
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
              '${distanceKm.toStringAsFixed(1)} km',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
