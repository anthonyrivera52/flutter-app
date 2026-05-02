import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OSMMapService {
  static final OSMMapService _instance = OSMMapService._internal();
  factory OSMMapService() => _instance;
  OSMMapService._internal();

  final MapController _mapController = MapController();
  MapController get mapController => _mapController;

  static const String _userAgent = 'com.innotechlab.tienda';

  static final MapTileConfig defaultTileConfig = MapTileConfig.cartoVoyager;

  TileLayer createTileLayer({MapTileConfig? config}) {
    final tileConfig = config ?? defaultTileConfig;
    return TileLayer(
      urlTemplate: tileConfig.urlTemplate,
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: _userAgent,
      maxZoom: 18,
      minZoom: 1,
    );
  }

  Widget buildMap({
    required LatLng? initialPosition,
    required List<Marker> markers,
    MapTileConfig? tileConfig,
    ValueChanged<LatLng>? onMapTap,
    ValueChanged<Marker>? onMarkerTap,
    ValueChanged<MapCamera>? onCameraMove,
    double initialZoom = 14.0,
  }) {
    final center = initialPosition ?? const LatLng(4.7110, -74.0721);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: initialZoom,
        minZoom: 3,
        maxZoom: 18,
        onTap: (tapPosition, point) => onMapTap?.call(point),
        onPositionChanged: (camera, hasGesture) {
          onCameraMove?.call(camera);
        },
      ),
      children: [
        createTileLayer(config: tileConfig),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Future<void> animateToPosition(
    LatLng position, {
    double? zoom,
    double padding = 50,
  }) async {
    _mapController.move(position, zoom ?? _mapController.camera.zoom);
  }

  Future<void> fitBounds(LatLngBounds bounds, {double padding = 50}) async {
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(padding)),
    );
  }

  LatLng get center => _mapController.camera.center;
  double get zoom => _mapController.camera.zoom;
}

class MapTileConfig {
  final String urlTemplate;
  final String name;
  final bool isDark;

  const MapTileConfig({
    required this.urlTemplate,
    required this.name,
    this.isDark = false,
  });

  static const cartoVoyager = MapTileConfig(
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    name: 'Voyager',
    isDark: false,
  );

  static const cartoPositron = MapTileConfig(
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/positron/{z}/{x}/{y}{r}.png',
    name: 'Positron',
    isDark: false,
  );

  static const cartoDarkMatter = MapTileConfig(
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/dark_matter/{z}/{x}/{y}{r}.png',
    name: 'Dark Matter',
    isDark: true,
  );

  static const openStreetMap = MapTileConfig(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    name: 'OpenStreetMap',
    isDark: false,
  );
}

class OSMMarker {
  static Marker createShopMarker({
    required String shopId,
    required LatLng position,
    required bool isOpen,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: position,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          decoration: BoxDecoration(
            color: isOpen ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            isOpen ? Icons.store : Icons.store_mall_directory,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  static Marker createUserMarker(LatLng position) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
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
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }

  static Marker createDeliveryMarker(LatLng position) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
      ),
    );
  }
}

class OfflineMapHelper {
  static LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));
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

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}
