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

class _FullMapWidgetState extends State<FullMapWidget> {
  late final MapController _mapController;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
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
            ],
          ),
        ),
      );
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
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.innotechlab.tienda',
        ),
        MarkerLayer(
          markers: [
            if (widget.userLatitude != 0 && widget.userLongitude != 0)
              Marker(
                point: userLocation,
                width: 40,
                height: 40,
                child: Container(
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
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ...widget.nearbyShops.map((shopDistance) {
              final shop = shopDistance.shop;
              final isSelected = widget.selectedShop?.id == shop.id;
              return Marker(
                point: LatLng(shop.latitude, shop.longitude),
                width: isSelected ? 60 : 50,
                height: isSelected ? 60 : 50,
                child: GestureDetector(
                  onTap: () => widget.onShopSelected(shop),
                  child: _MapMarker(
                    shop: shop,
                    distanceKm: shopDistance.distanceKm,
                    isSelected: isSelected,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  final Shop shop;
  final double distanceKm;
  final bool isSelected;

  const _MapMarker({
    required this.shop,
    required this.distanceKm,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSelected ? 48 : 40,
          height: isSelected ? 48 : 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
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
                      size: isSelected ? 24 : 20,
                      color: Colors.grey,
                    ),
                  )
                : Icon(
                    Icons.store,
                    size: isSelected ? 24 : 20,
                    color: Colors.grey,
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
