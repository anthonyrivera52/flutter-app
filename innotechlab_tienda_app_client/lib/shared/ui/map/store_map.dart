import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_app/shared/ui/map/osm_map_service.dart';
import 'package:flutter_app/shared/ui/map/shop_marker.dart';

class StoreMapWidget extends StatefulWidget {
  final List<ShopMarkerData> shops;
  final latlong.LatLng? userLocation;
  final String? selectedShopId;
  final ValueChanged<ShopMarkerData>? onShopSelected;
  final ValueChanged<latlong.LatLng>? onMapTap;
  final bool showControls;
  final bool showUserLocation;
  final double initialZoom;
  final latlong.LatLng? initialCenter;
  final bool fitBoundsToShops;

  const StoreMapWidget({
    super.key,
    required this.shops,
    this.userLocation,
    this.selectedShopId,
    this.onShopSelected,
    this.onMapTap,
    this.showControls = true,
    this.showUserLocation = true,
    this.initialZoom = 13.0,
    this.initialCenter,
    this.fitBoundsToShops = true,
  });

  @override
  State<StoreMapWidget> createState() => _StoreMapWidgetState();
}

class _StoreMapWidgetState extends State<StoreMapWidget> {
  late final OSMMapService _mapService;
  late final MapController _mapController;
  List<Marker> _markers = [];
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _mapService = OSMMapService();
    _mapController = _mapService.mapController;
    _loadMarkers();
  }

  @override
  void didUpdateWidget(StoreMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shops != widget.shops ||
        oldWidget.selectedShopId != widget.selectedShopId ||
        oldWidget.userLocation != widget.userLocation) {
      _loadMarkers();
    }

    if (!_hasAnimated && widget.fitBoundsToShops && _openShops.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<ShopMarkerData> get _openShops {
    return widget.shops.where((s) => s.isOpen).toList();
  }

  void _loadMarkers() {
    final List<Marker> markers = [];

    if (widget.showUserLocation && widget.userLocation != null) {
      markers.add(OSMMarker.createUserMarker(widget.userLocation!));
    }

    for (final shop in _openShops) {
      final isSelected = shop.id == widget.selectedShopId;

      markers.add(
        Marker(
          point: latlong.LatLng(
            shop.position.latitude,
            shop.position.longitude,
          ),
          width: isSelected ? 52 : 44,
          height: 60,
          child: GestureDetector(
            onTap: () => widget.onShopSelected?.call(shop),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSelected ? 52 : 44,
                  height: isSelected ? 52 : 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            shop.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.store,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        )
                      : const Icon(Icons.store, color: Colors.grey, size: 22),
                ),
                if (shop.distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${shop.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    final allPoints = _markers.map((m) => m.point).toList();
    if (allPoints.isEmpty) return;

    final bounds = OfflineMapHelper.calculateBounds(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
    _hasAnimated = true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                widget.initialCenter ??
                widget.userLocation ??
                const latlong.LatLng(4.7110, -74.0721),
            initialZoom: widget.initialZoom,
            minZoom: 3,
            maxZoom: 18,
            onTap: (tapPosition, point) => widget.onMapTap?.call(point),
          ),
          children: [
            _mapService.createTileLayer(),
            MarkerLayer(markers: _markers),
          ],
        ),
        if (widget.showControls)
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.userLocation != null)
                  FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    onPressed: () {
                      _mapController.move(
                        widget.userLocation!,
                        _mapController.camera.zoom,
                      );
                    },
                    child: const Icon(Icons.my_location),
                  ),
                if (widget.fitBoundsToShops && _openShops.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    onPressed: _fitBounds,
                    child: const Icon(Icons.map),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
