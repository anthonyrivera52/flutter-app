import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'abstract_map_service.dart';

class GoogleMapService implements BaseMapService {
  @override
  Widget buildMap({
    required LatLng? initialPosition,
    required Set<Marker> markers,
    required ValueChanged<LatLng>? onMapTap,
    required ValueChanged<Marker>? onMarkerTap,
    required ValueChanged<CameraPosition>? onCameraMove,
    required ValueChanged<LatLngBounds>? onBoundsChanged,
  }) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition ?? const LatLng(0, 0),
        zoom: 14,
      ),
      markers: markers,
      onTap: onMapTap,
      onCameraMove: onCameraMove,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false, // We'll add custom controls if needed
      mapType: MapType.normal,
      // Performance optimizations
      indoorViewEnabled: false,
      trafficEnabled: false,
    );
  }

  @override
  Future<BitmapDescriptor> createMarkerIconFromAsset(
    String assetPath, {
    double scale = 1.0,
  }) async {
    return await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: scale * 2.0),
      assetPath,
    );
  }

  @override
  Future<BitmapDescriptor> createMarkerIconFromNetwork(
    String url, {
    required int width,
    required int height,
  }) async {
    try {
      // Download image
      final ByteData data = await rootBundle.load(url);
      final Uint8List imgBytes = data.buffer.asUint8List();

      // For simplicity, we're returning the original size
      // In a production app, you'd want to resize using an image processing package
      return BitmapDescriptor.fromBytes(imgBytes);
    } catch (e) {
      // Fallback to a default icon if loading fails
      return BitmapDescriptor.defaultMarker;
    }
  }
}
