import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/shared/ui/map/google_map_service.dart';

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
  late final GoogleMapService _mapService;
  late final GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _mapService = GoogleMapService();
    _loadMarkers();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    final Set<Marker> markers = {};

    // Add user location marker
    final userMarkerIcon = await _mapService.createMarkerIconFromAsset(
      'assets/icons/user_location.png',
    );

    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(widget.userLatitude, widget.userLongitude),
        icon: userMarkerIcon,
      ),
    );

    // Add shop markers
    for (final shopDistance in widget.nearbyShops) {
      final shop = shopDistance.shop;
      final shopMarkerIcon = await _mapService.createMarkerIconFromAsset(
        'assets/icons/shop_marker.png',
      );

      markers.add(
        Marker(
          markerId: MarkerId('shop_${shop.id}'),
          position: LatLng(shop.latitude, shop.longitude),
          icon: shopMarkerIcon,
          onTap: () => widget.onShopTap(shop),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
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
    final bounds = _getBoundsFromLatLngList(allPoints);

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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController.animateCamera(
                CameraUpdate.newLatLngBounds(
                  bounds,
                  50.0, // padding
                ),
              );
            },
            onTap: (position) => {}, // Handle map tap if needed
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled:
                false, // We'll use custom controls if needed
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'center_map',
              onPressed: () {
                _mapController.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    bounds,
                    50.0, // padding
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

  LatLngBounds _getBoundsFromLatLngList(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(southwest: LatLng(0, 0), northeast: LatLng(0, 0));
    }

    double minLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLat = points.first.latitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
