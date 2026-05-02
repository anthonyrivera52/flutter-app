import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/shared/ui/map/osm_map_service.dart';

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
  late final OSMMapService _mapService;
  late final MapController _mapController;
  List<Marker> _markers = [];
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _mapService = OSMMapService();
    _mapController = _mapService.mapController;
  }

  @override
  void didUpdateWidget(FullMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.nearbyShops != oldWidget.nearbyShops ||
        widget.selectedShop?.id != oldWidget.selectedShop?.id) {
      _updateMarkers();
    }

    if (widget.selectedShop != null &&
        widget.selectedShop?.id != oldWidget.selectedShop?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(widget.selectedShop!.latitude, widget.selectedShop!.longitude),
          16,
        );
      });
    } else if (widget.userLatitude != 0 &&
        widget.userLatitude != oldWidget.userLatitude &&
        widget.nearbyShops.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    } else if (widget.selectedShop == null &&
        (widget.nearbyShops.length != oldWidget.nearbyShops.length ||
            (widget.nearbyShops.isNotEmpty &&
                oldWidget.nearbyShops.isNotEmpty &&
                widget.nearbyShops.first.shop.id !=
                    oldWidget.nearbyShops.first.shop.id))) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    } else if (!_hasAnimated &&
        widget.nearbyShops.isNotEmpty &&
        widget.userLatitude != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  List<ShopDistance> get _openShops {
    return widget.nearbyShops.where((sd) => sd.shop.isOpen).toList();
  }

  void _updateMarkers() {
    final markers = <Marker>[];

    if (widget.userLatitude != 0 && widget.userLongitude != 0) {
      markers.add(
        OSMMarker.createUserMarker(
          LatLng(widget.userLatitude, widget.userLongitude),
        ),
      );
    }

    for (final shopDistance in _openShops) {
      final shop = shopDistance.shop;
      final isSelected = widget.selectedShop?.id == shop.id;

      markers.add(
        Marker(
          point: LatLng(shop.latitude, shop.longitude),
          width: isSelected ? 60 : 50,
          height: 60,
          child: GestureDetector(
            onTap: () => widget.onShopSelected(shop),
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
                      color: isSelected ? AppColors.primaryColor : Colors.grey,
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
                  child: const Icon(Icons.store, color: Colors.grey, size: 22),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '${shopDistance.distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
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
    if (!mounted) return;
    if (_openShops.isEmpty) return;

    final allPoints = <LatLng>[];

    if (widget.userLatitude != 0 && widget.userLongitude != 0) {
      allPoints.add(LatLng(widget.userLatitude, widget.userLongitude));
    }

    for (final sd in _openShops) {
      allPoints.add(LatLng(sd.shop.latitude, sd.shop.longitude));
    }

    if (allPoints.isEmpty) return;

    final bounds = OfflineMapHelper.calculateBounds(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
    _hasAnimated = true;
  }

  LatLng get _initialPosition {
    if (widget.userLatitude != 0) {
      return LatLng(widget.userLatitude, widget.userLongitude);
    } else if (widget.nearbyShops.isNotEmpty) {
      return LatLng(
        widget.nearbyShops.first.shop.latitude,
        widget.nearbyShops.first.shop.longitude,
      );
    }
    return const LatLng(4.7110, -74.0721);
  }

  @override
  Widget build(BuildContext context) {
    if (_markers.isEmpty && _openShops.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMarkers();
        if (!_hasAnimated) {
          _fitBounds();
        }
      });
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialPosition,
        initialZoom: widget.userLatitude != 0 || widget.nearbyShops.isNotEmpty
            ? 15
            : 2,
        minZoom: 3,
        maxZoom: 18,
        onTap: (tapPosition, point) {},
      ),
      children: [
        _mapService.createTileLayer(),
        MarkerLayer(markers: _markers),
      ],
    );
  }
}
