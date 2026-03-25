import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/core/utils/app_colors.dart';

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
  GoogleMapController? _mapController;
  bool _hasAnimated = false;
  final Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _markerCache = {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _fitBounds() {
    if (!mounted) return;
    if (widget.nearbyShops.isEmpty) return;

    final shopLocations = widget.nearbyShops
        .map((sd) => LatLng(sd.shop.latitude, sd.shop.longitude))
        .toList();

    if (widget.userLatitude != 0 && widget.userLongitude != 0) {
      shopLocations.add(LatLng(widget.userLatitude, widget.userLongitude));
    }

    if (shopLocations.isEmpty || _mapController == null) return;

    if (shopLocations.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(shopLocations.first, 15),
      );
      setState(() => _hasAnimated = true);
      return;
    }

    double minLat = shopLocations.first.latitude;
    double maxLat = shopLocations.first.latitude;
    double minLng = shopLocations.first.longitude;
    double maxLng = shopLocations.first.longitude;

    for (final loc in shopLocations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    setState(() => _hasAnimated = true);
  }

  void _animateToLocation(LatLng point, double zoom) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, zoom));
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
        _animateToLocation(
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

  Future<BitmapDescriptor> _createShopMarker({
    required String logoUrl,
    required double distanceKm,
    required bool isSelected,
  }) async {
    final cacheKey =
        'shop_${logoUrl.hashCode}_${distanceKm.toStringAsFixed(1)}_$isSelected';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    const double markerWidth = 60;
    const double markerHeight = 85;
    const double circleSize = 44;
    const double badgeHeight = 20;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      const Offset(markerWidth / 2, circleSize / 2 + 3),
      circleSize / 2 + 2,
      shadowPaint,
    );

    // Draw distance badge
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH((markerWidth - 50) / 2, circleSize + 8, 50, badgeHeight),
      const Radius.circular(10),
    );
    final badgePaint = Paint()
      ..color = isSelected ? AppColors.primaryColor : Colors.white;
    canvas.drawRRect(badgeRect, badgePaint);

    // Draw badge text
    final textSpan = TextSpan(
      text: '${distanceKm.toStringAsFixed(1)} km',
      style: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (markerWidth - textPainter.width) / 2,
        circleSize + 10 + (badgeHeight - textPainter.height) / 2,
      ),
    );

    // Draw circle background
    final circlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(markerWidth / 2, circleSize / 2),
      circleSize / 2,
      circlePaint,
    );

    // Draw circle border
    final borderPaint = Paint()
      ..color = isSelected ? AppColors.primaryColor : Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    canvas.drawCircle(
      Offset(markerWidth / 2, circleSize / 2),
      circleSize / 2 - 1,
      borderPaint,
    );

    // Draw store icon
    final iconPaint = Paint()..color = Colors.grey.shade600;
    final iconCenter = Offset(markerWidth / 2, circleSize / 2);
    final iconSize = 20.0;
    final path = Path();
    path.moveTo(iconCenter.dx - iconSize / 2, iconCenter.dy + iconSize / 3);
    path.lineTo(iconCenter.dx - iconSize / 2, iconCenter.dy - iconSize / 3);
    path.lineTo(iconCenter.dx - iconSize / 4, iconCenter.dy - iconSize / 3);
    path.lineTo(iconCenter.dx - iconSize / 4, iconCenter.dy - iconSize / 2);
    path.lineTo(iconCenter.dx + iconSize / 4, iconCenter.dy - iconSize / 2);
    path.lineTo(iconCenter.dx + iconSize / 4, iconCenter.dy - iconSize / 3);
    path.lineTo(iconCenter.dx + iconSize / 2, iconCenter.dy - iconSize / 3);
    path.lineTo(iconCenter.dx + iconSize / 2, iconCenter.dy + iconSize / 3);
    path.close();
    canvas.drawPath(path, iconPaint);

    final image = await recorder.endRecording().toImage(
      markerWidth.toInt(),
      markerHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(bytes);
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  Future<BitmapDescriptor> _createUserMarker() async {
    const cacheKey = 'user_marker';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    const double markerSize = 44;
    const double pulseSize = 44;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw pulse circle (outer)
    final pulsePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      pulseSize / 2,
      pulsePaint,
    );

    // Draw main circle
    final circlePaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(markerSize / 2, markerSize / 2), 20, circlePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(markerSize / 2, markerSize / 2), 20, borderPaint);

    // Draw person icon
    final iconPaint = Paint()..color = Colors.white;
    final iconCenter = Offset(markerSize / 2, markerSize / 2);

    // Head
    canvas.drawCircle(Offset(iconCenter.dx, iconCenter.dy - 4), 5, iconPaint);

    // Body
    final bodyPath = Path();
    bodyPath.moveTo(iconCenter.dx - 7, iconCenter.dy + 10);
    bodyPath.quadraticBezierTo(
      iconCenter.dx,
      iconCenter.dy - 2,
      iconCenter.dx + 7,
      iconCenter.dy + 10,
    );
    bodyPath.close();
    canvas.drawPath(bodyPath, iconPaint);

    final image = await recorder.endRecording().toImage(
      markerSize.toInt(),
      markerSize.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(bytes);
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  void _updateMarkers() async {
    final markers = <Marker>{};

    // User marker
    if (widget.userLatitude != 0 && widget.userLongitude != 0) {
      final userIcon = await _createUserMarker();
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(widget.userLatitude, widget.userLongitude),
          icon: userIcon,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );
    }

    // Shop markers
    for (final shopDistance in widget.nearbyShops) {
      final shop = shopDistance.shop;
      final isSelected = widget.selectedShop?.id == shop.id;

      final markerIcon = await _createShopMarker(
        logoUrl: shop.logoUrl,
        distanceKm: shopDistance.distanceKm,
        isSelected: isSelected,
      );

      markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.latitude, shop.longitude),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: shop.name,
            snippet: '${shopDistance.distanceKm.toStringAsFixed(1)} km',
          ),
          onTap: () {
            widget.onShopSelected(shop);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });
    }
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
    return const LatLng(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: widget.userLatitude != 0 || widget.nearbyShops.isNotEmpty
            ? 15
            : 2,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMarkers();
        if (!_hasAnimated) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
        }
      },
      markers: _markers,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onTap: (LatLng point) {},
    );
  }
}
