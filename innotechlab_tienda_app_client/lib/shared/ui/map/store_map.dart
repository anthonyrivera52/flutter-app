import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'base_map.dart';
import 'location_marker.dart';
import 'shop_marker.dart';
import 'route_layer.dart';
import 'map_controls.dart';

class StoreMapWidget extends StatefulWidget {
  final List<ShopMarkerData> shops;
  final LatLng? userLocation;
  final String? selectedShopId;
  final ValueChanged<ShopMarkerData>? onShopSelected;
  final ValueChanged<TapPosition>? onMapTap;
  final MapTileConfig tileConfig;
  final MapControlsOptions controlsOptions;
  final bool showControls;
  final bool showUserLocation;
  final double initialZoom;
  final LatLng? initialCenter;
  final bool fitBoundsToShops;
  final List<RouteData> routes;

  const StoreMapWidget({
    super.key,
    required this.shops,
    this.userLocation,
    this.selectedShopId,
    this.onShopSelected,
    this.onMapTap,
    this.tileConfig = const MapTileConfig(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      name: 'Voyager',
    ),
    this.controlsOptions = const MapControlsOptions(),
    this.showControls = true,
    this.showUserLocation = true,
    this.initialZoom = 13.0,
    this.initialCenter,
    this.fitBoundsToShops = true,
    this.routes = const [],
  });

  @override
  State<StoreMapWidget> createState() => _StoreMapWidgetState();
}

class _StoreMapWidgetState extends State<StoreMapWidget> {
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
    if (widget.shops.isEmpty) return;

    final points = widget.shops.map((s) => s.position).toList();

    if (widget.userLocation != null) {
      points.add(widget.userLocation!);
    }

    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
    _hasAnimated = true;
  }

  @override
  void didUpdateWidget(StoreMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasAnimated && widget.fitBoundsToShops && widget.shops.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
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
                (widget.userLocation ?? const LatLng(0, 0)),
            initialZoom: widget.initialZoom,
            onMapReady: () {
              if (widget.fitBoundsToShops && widget.shops.isNotEmpty) {
                _fitBounds();
              }
            },
            onTap: (tapPosition, point) => widget.onMapTap?.call(tapPosition),
          ),
          children: [
            MapBaseDefaults.tileLayer(config: widget.tileConfig),
            if (widget.routes.isNotEmpty)
              RouteLayerWidget(routes: widget.routes),
            MarkerLayer(
              markers: [
                if (widget.showUserLocation && widget.userLocation != null)
                  Marker(
                    point: widget.userLocation!,
                    width: 44,
                    height: 44,
                    child: const UserLocationMarkerWidget(),
                  ),
                ...widget.shops.map((shop) {
                  final isSelected = shop.id == widget.selectedShopId;
                  return Marker(
                    point: shop.position,
                    width: isSelected ? 64 : 54,
                    height: 80,
                    child: ShopMarker(
                      shop: shop,
                      isSelected: isSelected,
                      onTap: () => widget.onShopSelected?.call(shop),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        if (widget.showControls)
          Positioned(
            right: 12,
            bottom: 12,
            child: MapControls(
              mapController: _mapController,
              options: widget.controlsOptions,
              userLocation: widget.userLocation,
              boundsToFit: widget.shops.isNotEmpty
                  ? LatLngBounds.fromPoints(
                      widget.shops.map((s) => s.position).toList(),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class SimpleStoreMap extends StatelessWidget {
  final List<ShopMarkerData> shops;
  final LatLng? userLocation;
  final String? selectedShopId;
  final ValueChanged<ShopMarkerData>? onShopSelected;
  final double height;
  final bool interactive;

  const SimpleStoreMap({
    super.key,
    required this.shops,
    this.userLocation,
    this.selectedShopId,
    this.onShopSelected,
    this.height = 200,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('No hay tiendas disponibles')),
        ),
      );
    }

    final points = shops.map((s) => s.position).toList();
    if (userLocation != null) {
      points.add(userLocation!);
    }
    final bounds = LatLngBounds.fromPoints(points);

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.innotechlab.tienda',
            ),
            MarkerLayer(
              markers: [
                if (userLocation != null)
                  Marker(
                    point: userLocation!,
                    width: 30,
                    height: 30,
                    child: UserLocationMarkerWidget(),
                  ),
                ...shops.map((shop) {
                  final isSelected = shop.id == selectedShopId;
                  return Marker(
                    point: shop.position,
                    width: isSelected ? 60 : 50,
                    height: 70,
                    child: ShopMarker(
                      shop: shop,
                      isSelected: isSelected,
                      onTap: () => onShopSelected?.call(shop),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
