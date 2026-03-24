import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class BaseMapService {
  Widget buildMap({
    required LatLng? initialPosition,
    required Set<Marker> markers,
    required ValueChanged<LatLng>? onMapTap,
    required ValueChanged<Marker>? onMarkerTap,
    required ValueChanged<CameraPosition>? onCameraMove,
    required ValueChanged<LatLngBounds>? onBoundsChanged,
  });

  Future<BitmapDescriptor> createMarkerIconFromAsset(
    String assetPath, {
    double scale = 1.0,
  });

  Future<BitmapDescriptor> createMarkerIconFromNetwork(
    String url, {
    required int width,
    required int height,
  });
}
