import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_app/shared/ui/map/google_map_service.dart';
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
  late final GoogleMapService _mapService;
  late final GoogleMapController _mapController;
  bool _hasAnimated = false;
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

    // Add user location marker if enabled and available
    if (widget.showUserLocation && widget.userLocation != null) {
      final userMarkerIcon = await _mapService.createMarkerIconFromAsset(
        'assets/icons/user_location.png',
      );

      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            widget.userLocation!.latitude,
            widget.userLocation!.longitude,
          ),
          icon: userMarkerIcon,
        ),
      );
    }

    // Add shop markers
    for (final shop in widget.shops) {
      final isSelected = shop.id == widget.selectedShopId;
      final shopMarkerIcon = await _mapService.createMarkerIconFromAsset(
        'assets/icons/shop_marker.png',
      );

      markers.add(
        Marker(
          markerId: MarkerId('shop_${shop.id}'),
          position: LatLng(shop.position.latitude, shop.position.longitude),
          icon: shopMarkerIcon,
          onTap: () => widget.onShopSelected?.call(shop),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _fitBounds() {
    if (widget.shops.isEmpty) return;

    // Initialize bounds with extreme values
    double minLat = double.infinity;
    double minLng = double.infinity;
    double maxLat = -double.infinity;
    double maxLng = -double.infinity;

    // Process shop locations
    for (final shop in widget.shops) {
      final lat = shop.position.latitude;
      final lng = shop.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lng < minLng) minLng = lng;
      if (lat > maxLat) maxLat = lat;
      if (lng > maxLng) maxLng = lng;
    }

    // Process user location if available
    if (widget.userLocation != null) {
      final lat = widget.userLocation!.latitude;
      final lng = widget.userLocation!.longitude;
      if (lat < minLat) minLat = lat;
      if (lng < minLng) minLng = lng;
      if (lat > maxLat) maxLat = lat;
      if (lng > maxLng) maxLng = lng;
    }

    // Check if we have any valid points
    if (minLat == double.infinity) {
      return; // No valid points to fit
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        80.0, // padding as double
      ),
      duration: const Duration(milliseconds: 500),
    );
    _hasAnimated = true;
  }

  @override
  void didUpdateWidget(StoreMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasAnimated && widget.fitBoundsToShops && widget.shops.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }

    // Reload markers if shops or selected shop changed
    if (oldWidget.shops != widget.shops ||
        oldWidget.selectedShopId != widget.selectedShopId) {
      _loadMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter != null
                ? LatLng(
                    widget.initialCenter!.latitude,
                    widget.initialCenter!.longitude,
                  )
                : widget.userLocation != null
                ? LatLng(
                    widget.userLocation!.latitude,
                    widget.userLocation!.longitude,
                  )
                : const LatLng(0, 0),
            zoom: widget.initialZoom,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            if (widget.fitBoundsToShops && widget.shops.isNotEmpty) {
              _fitBounds();
            }
          },
          onTap: (position) => widget.onMapTap?.call(
            latlong.LatLng(position.latitude, position.longitude),
          ),
          markers: _markers,
          myLocationEnabled: widget.showUserLocation,
          myLocationButtonEnabled: false, // We'll use custom controls
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          // Performance optimizations
          indoorViewEnabled: false,
          trafficEnabled: false,
        ),
        if (widget.showControls)
          Positioned(
            right: 12,
            bottom: 12,
            child: _MapControls(
              mapController: _mapController,
              userLocation: widget.userLocation,
              boundsToFit: widget.shops.isNotEmpty
                  ? LatLngBounds(
                      southwest: LatLng(
                        widget.shops
                            .map((s) => s.position.latitude)
                            .reduce((a, b) => a < b ? a : b),
                        widget.shops
                            .map((s) => s.position.longitude)
                            .reduce((a, b) => a < b ? a : b),
                      ),
                      northeast: LatLng(
                        widget.shops
                            .map((s) => s.position.latitude)
                            .reduce((a, b) => a > b ? a : b),
                        widget.shops
                            .map((s) => s.position.longitude)
                            .reduce((a, b) => a > b ? a : b),
                      ),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _MapControls extends StatelessWidget {
  final GoogleMapController mapController;
  final latlong.LatLng? userLocation;
  final LatLngBounds? boundsToFit;

  const _MapControls({
    required this.mapController,
    this.userLocation,
    this.boundsToFit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // My location button
        if (userLocation != null)
          FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            onPressed: () {
              mapController.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(userLocation!.latitude, userLocation!.longitude),
                ),
                duration: const Duration(milliseconds: 300),
              );
            },
            child: const Icon(Icons.my_location),
          ),
        // Fit bounds button
        if (boundsToFit != null)
          FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            onPressed: () {
              mapController.animateCamera(
                CameraUpdate.newLatLngBounds(
                  boundsToFit!,
                  50.0, // padding as double
                ),
                duration: const Duration(milliseconds: 500),
              );
            },
            child: const Icon(Icons.map),
          ),
      ],
    );
  }
}
