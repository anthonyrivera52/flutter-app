import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/shared/ui/map/osm_map_service.dart';

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
  late final OSMMapService _mapService;
  late final MapController _mapController;
  List<Marker> _markers = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _mapService = OSMMapService();
    _mapController = _mapService.mapController;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadMarkers();
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(ShopMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nearbyShops != widget.nearbyShops ||
        oldWidget.userLatitude != widget.userLatitude ||
        oldWidget.userLongitude != widget.userLongitude) {
      _loadMarkers();
      _fitBoundsIfNeeded();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<ShopDistance> get _openShops {
    return widget.nearbyShops.where((sd) => sd.shop.isOpen).toList();
  }

  void _loadMarkers() {
    final List<Marker> markers = [];
    final userLocation = LatLng(widget.userLatitude, widget.userLongitude);

    markers.add(OSMMarker.createUserMarker(userLocation));

    for (final shopDistance in _openShops) {
      final shop = shopDistance.shop;
      final position = LatLng(shop.latitude, shop.longitude);

      markers.add(
        OSMMarker.createShopMarker(
          shopId: shop.id,
          position: position,
          isOpen: shop.isOpen,
          onTap: () => widget.onShopTap(shop),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _fitBoundsIfNeeded() {
    if (_markers.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allPoints = _markers.map((m) => m.point).toList();
      if (allPoints.isEmpty) return;

      final bounds = OfflineMapHelper.calculateBounds(allPoints);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_openShops.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No hay sucursales abiertas cercanas')),
      );
    }

    final userLocation = LatLng(widget.userLatitude, widget.userLongitude);

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
              initialCenter: userLocation,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              _mapService.createTileLayer(),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'center_map',
              onPressed: _fitBoundsIfNeeded,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
