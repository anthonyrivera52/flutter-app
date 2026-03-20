import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LocationMarkerOptions {
  final double size;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool enablePulse;
  final Color pulseColor;
  final IconData icon;

  const LocationMarkerOptions({
    this.size = 40,
    this.color = Colors.blue,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
    this.enablePulse = true,
    this.pulseColor = Colors.blue,
    this.icon = Icons.person,
  });

  LocationMarkerOptions copyWith({
    double? size,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    bool? enablePulse,
    Color? pulseColor,
    IconData? icon,
  }) {
    return LocationMarkerOptions(
      size: size ?? this.size,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      enablePulse: enablePulse ?? this.enablePulse,
      pulseColor: pulseColor ?? this.pulseColor,
      icon: icon ?? this.icon,
    );
  }
}

class UserLocationMarker extends StatefulWidget {
  final LatLng position;
  final LocationMarkerOptions options;
  final VoidCallback? onTap;

  const UserLocationMarker({
    super.key,
    required this.position,
    this.options = const LocationMarkerOptions(),
    this.onTap,
  });

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.options.enablePulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(UserLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options.enablePulse && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.options.enablePulse && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.options.size;
    final color = widget.options.color;
    final borderColor = widget.options.borderColor;
    final borderWidth = widget.options.borderWidth;
    final icon = widget.options.icon;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.options.enablePulse)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: size * _pulseAnimation.value,
                  height: size * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    color: widget.options.pulseColor.withValues(
                      alpha: 0.3 / _pulseAnimation.value,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.55),
          ),
        ],
      ),
    );
  }
}

class UserLocationMarkerWidget extends StatelessWidget {
  final LatLng? position;
  final LocationMarkerOptions options;
  final VoidCallback? onTap;

  const UserLocationMarkerWidget({
    super.key,
    this.position,
    this.options = const LocationMarkerOptions(),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UserLocationMarker(
      position: position ?? const LatLng(0, 0),
      options: options,
      onTap: onTap,
    );
  }
}
