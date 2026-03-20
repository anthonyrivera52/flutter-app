import 'package:flutter/material.dart' show EdgeInsets;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum MapStyle { cartoVoyager, cartoPositron, cartoDarkMatter, openStreetMap }

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

  static MapTileConfig fromStyle(MapStyle style) {
    switch (style) {
      case MapStyle.cartoVoyager:
        return cartoVoyager;
      case MapStyle.cartoPositron:
        return cartoPositron;
      case MapStyle.cartoDarkMatter:
        return cartoDarkMatter;
      case MapStyle.openStreetMap:
        return openStreetMap;
    }
  }
}

class MapBaseOptions {
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final LatLng? initialCenter;
  final bool enableRotation;
  final bool enableZoom;
  final bool enablePan;
  final double rotation;
  final double defaultPadding;

  const MapBaseOptions({
    this.initialZoom = 13.0,
    this.minZoom = 3.0,
    this.maxZoom = 18.0,
    this.initialCenter,
    this.enableRotation = true,
    this.enableZoom = true,
    this.enablePan = true,
    this.rotation = 0.0,
    this.defaultPadding = 50.0,
  });

  MapOptions toMapOptions({
    LatLng? center,
    CameraFit? initialCameraFit,
    void Function()? onMapReady,
    void Function(TapPosition, LatLng)? onTap,
    void Function(TapPosition, LatLng)? onLongPress,
    void Function(MapCamera, bool)? onPositionChanged,
  }) {
    return MapOptions(
      initialCenter: center ?? initialCenter ?? const LatLng(0, 0),
      initialZoom: initialZoom,
      minZoom: minZoom,
      maxZoom: maxZoom,
      initialRotation: rotation,
      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      initialCameraFit: initialCameraFit,
      onMapReady: onMapReady,
      onTap: onTap,
      onLongPress: onLongPress,
      onPositionChanged: onPositionChanged != null
          ? (camera, hasGesture) => onPositionChanged(camera, hasGesture)
          : null,
    );
  }
}

class MapBaseDefaults {
  static const userAgentPackageName = 'com.innotechlab.tienda';

  static TileLayer tileLayer({MapTileConfig? config}) {
    final tileConfig = config ?? MapTileConfig.cartoVoyager;
    return TileLayer(
      urlTemplate: tileConfig.urlTemplate,
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: userAgentPackageName,
    );
  }
}

extension LatLngBoundsExtension on LatLngBounds {
  CameraFit toCameraFit({double padding = 50}) {
    return CameraFit.bounds(bounds: this, padding: EdgeInsets.all(padding));
  }
}

extension MapCameraExtension on MapCamera {
  LatLng get centerLatLng => center;
}
