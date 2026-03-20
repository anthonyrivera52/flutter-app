import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapControlsOptions {
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;
  final double buttonSize;
  final double spacing;
  final bool showZoomControls;
  final bool showLocationButton;
  final bool showCompass;
  final bool showFullscreen;
  final bool isDarkMode;

  const MapControlsOptions({
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black87,
    this.iconSize = 20,
    this.buttonSize = 40,
    this.spacing = 8,
    this.showZoomControls = true,
    this.showLocationButton = true,
    this.showCompass = false,
    this.showFullscreen = false,
    this.isDarkMode = false,
  });

  MapControlsOptions copyWith({
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
    double? buttonSize,
    double? spacing,
    bool? showZoomControls,
    bool? showLocationButton,
    bool? showCompass,
    bool? showFullscreen,
    bool? isDarkMode,
  }) {
    return MapControlsOptions(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconColor: iconColor ?? this.iconColor,
      iconSize: iconSize ?? this.iconSize,
      buttonSize: buttonSize ?? this.buttonSize,
      spacing: spacing ?? this.spacing,
      showZoomControls: showZoomControls ?? this.showZoomControls,
      showLocationButton: showLocationButton ?? this.showLocationButton,
      showCompass: showCompass ?? this.showCompass,
      showFullscreen: showFullscreen ?? this.showFullscreen,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  factory MapControlsOptions.dark() {
    return const MapControlsOptions(
      backgroundColor: Color(0xFF2C2C2C),
      iconColor: Colors.white,
      isDarkMode: true,
    );
  }
}

class MapControls extends StatelessWidget {
  final MapController mapController;
  final MapControlsOptions options;
  final LatLng? userLocation;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onFullscreenPressed;
  final CameraFit? fitBounds;
  final LatLngBounds? boundsToFit;

  const MapControls({
    super.key,
    required this.mapController,
    this.options = const MapControlsOptions(),
    this.userLocation,
    this.onLocationPressed,
    this.onZoomIn,
    this.onZoomOut,
    this.onFullscreenPressed,
    this.fitBounds,
    this.boundsToFit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (options.showLocationButton) ...[
            _buildLocationButton(),
            SizedBox(height: options.spacing),
          ],
          if (options.showZoomControls) ...[
            _buildZoomInButton(),
            SizedBox(height: 4),
            _buildZoomOutButton(),
          ],
          if (options.showFullscreen) ...[
            SizedBox(height: options.spacing),
            _buildFullscreenButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return _MapControlButton(
      icon: Icons.my_location,
      onPressed: () {
        onLocationPressed?.call();
        if (userLocation != null) {
          mapController.move(userLocation!, 15);
        } else if (boundsToFit != null) {
          mapController.fitCamera(
            CameraFit.bounds(
              bounds: boundsToFit!,
              padding: const EdgeInsets.all(50),
            ),
          );
        }
      },
      options: options,
      tooltip: 'Mi ubicación',
    );
  }

  Widget _buildZoomInButton() {
    return _MapControlButton(
      icon: Icons.add,
      onPressed: () {
        onZoomIn?.call();
        final currentZoom = mapController.camera.zoom;
        mapController.move(mapController.camera.center, currentZoom + 1);
      },
      options: options,
      tooltip: 'Acercar',
    );
  }

  Widget _buildZoomOutButton() {
    return _MapControlButton(
      icon: Icons.remove,
      onPressed: () {
        onZoomOut?.call();
        final currentZoom = mapController.camera.zoom;
        mapController.move(mapController.camera.center, currentZoom - 1);
      },
      options: options,
      tooltip: 'Alejar',
    );
  }

  Widget _buildFullscreenButton() {
    return _MapControlButton(
      icon: Icons.fullscreen,
      onPressed: onFullscreenPressed,
      options: options,
      tooltip: 'Pantalla completa',
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final MapControlsOptions options;
  final String tooltip;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    required this.options,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: options.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: options.buttonSize,
              height: options.buttonSize,
              child: Icon(
                icon,
                color: options.iconColor,
                size: options.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapControlsOverlay extends StatelessWidget {
  final MapController mapController;
  final LatLng? userLocation;
  final LatLngBounds? bounds;
  final MapControlsOptions options;
  final EdgeInsets padding;
  final VoidCallback? onLocationPressed;

  const MapControlsOverlay({
    super.key,
    required this.mapController,
    this.userLocation,
    this.bounds,
    this.options = const MapControlsOptions(),
    this.padding = const EdgeInsets.all(16),
    this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: MapControls(
        mapController: mapController,
        options: options,
        userLocation: userLocation,
        boundsToFit: bounds,
        onLocationPressed: onLocationPressed,
      ),
    );
  }
}

class ZoomButtonsWidget extends StatelessWidget {
  final MapController mapController;
  final double zoomStep;
  final MapControlsOptions options;

  const ZoomButtonsWidget({
    super.key,
    required this.mapController,
    this.zoomStep = 1.0,
    this.options = const MapControlsOptions(),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(
          icon: Icons.add,
          onPressed: () {
            final zoom = mapController.camera.zoom + zoomStep;
            mapController.move(mapController.camera.center, zoom);
          },
          options: options,
          tooltip: 'Acercar',
        ),
        const SizedBox(height: 4),
        _MapControlButton(
          icon: Icons.remove,
          onPressed: () {
            final zoom = mapController.camera.zoom - zoomStep;
            mapController.move(mapController.camera.center, zoom);
          },
          options: options,
          tooltip: 'Alejar',
        ),
      ],
    );
  }
}

class LocationButtonWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? location;
  final double targetZoom;
  final MapControlsOptions options;
  final VoidCallback? onPressed;

  const LocationButtonWidget({
    super.key,
    required this.mapController,
    this.location,
    this.targetZoom = 15.0,
    this.options = const MapControlsOptions(),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _MapControlButton(
      icon: Icons.my_location,
      onPressed: () {
        onPressed?.call();
        if (location != null) {
          mapController.move(location!, targetZoom);
        }
      },
      options: options,
      tooltip: 'Mi ubicación',
    );
  }
}
