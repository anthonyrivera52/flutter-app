import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_app/domain/entities/shop.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/home_viewmodel.dart';
import 'package:latlong2/latlong.dart';

class ShopMapWidget extends StatefulWidget {
  final List<ShopDistance> nearbyShops;
  final double userLatitude;
  final double userLongitude;
  final Shop? selectedShop;
  final ValueChanged<Shop> onShopTap;

  const ShopMapWidget({
    super.key,
    required this.nearbyShops,
    required this.userLatitude,
    required this.userLongitude,
    required this.selectedShop,
    required this.onShopTap,
  });

  @override
  State<ShopMapWidget> createState() => _ShopMapWidgetState();
}

class _ShopMapWidgetState extends State<ShopMapWidget> {
  late final MapController _mapController;

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

  @override
  Widget build(BuildContext context) {
    if (widget.nearbyShops.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No hay sucursales cercanas')),
      );
    }

    final userLocation = LatLng(widget.userLatitude, widget.userLongitude);
    final shopLocations = widget.nearbyShops
        .map((sd) => LatLng(sd.shop.latitude, sd.shop.longitude))
        .toList();

    final allPoints = [...shopLocations, userLocation];
    final bounds = LatLngBounds.fromPoints(allPoints);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.innotechlab.tienda',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLocation,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
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
                        onTap: () => widget.onShopTap(shop),
                        child: _ShopMarker(
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
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'center_map',
              onPressed: () {
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50),
                  ),
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.green),
            ),
          ),
        ],
      ),
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
              color: isSelected ? Colors.green : Colors.grey.shade300,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: shop.logoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: shop.logoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Icon(
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
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
