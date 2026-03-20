import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteLayerOptions {
  final Color color;
  final double strokeWidth;
  final double borderWidth;
  final Color? borderColor;
  final List<double>? dashArray;
  final bool isDotted;
  final bool isThick;

  const RouteLayerOptions({
    this.color = Colors.blue,
    this.strokeWidth = 4.0,
    this.borderWidth = 0,
    this.borderColor,
    this.dashArray,
    this.isDotted = false,
    this.isThick = false,
  });

  factory RouteLayerOptions.delivery() {
    return const RouteLayerOptions(
      color: Colors.blue,
      strokeWidth: 4.0,
      borderWidth: 1,
      borderColor: Colors.white,
    );
  }

  factory RouteLayerOptions.dashed() {
    return const RouteLayerOptions(
      color: Colors.orange,
      strokeWidth: 3.0,
      dashArray: [10, 10],
      isDotted: true,
    );
  }

  factory RouteLayerOptions.selected() {
    return const RouteLayerOptions(
      color: Colors.green,
      strokeWidth: 5.0,
      borderWidth: 2,
      borderColor: Colors.white,
      isThick: true,
    );
  }

  RouteLayerOptions copyWith({
    Color? color,
    double? strokeWidth,
    double? borderWidth,
    Color? borderColor,
    List<double>? dashArray,
    bool? isDotted,
    bool? isThick,
  }) {
    return RouteLayerOptions(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      dashArray: dashArray ?? this.dashArray,
      isDotted: isDotted ?? this.isDotted,
      isThick: isThick ?? this.isThick,
    );
  }
}

class RouteData {
  final String id;
  final List<LatLng> points;
  final RouteLayerOptions options;
  final String? label;
  final double? totalDistanceKm;
  final Duration? estimatedDuration;

  const RouteData({
    required this.id,
    required this.points,
    this.options = const RouteLayerOptions(),
    this.label,
    this.totalDistanceKm,
    this.estimatedDuration,
  });

  RouteData copyWith({
    String? id,
    List<LatLng>? points,
    RouteLayerOptions? options,
    String? label,
    double? totalDistanceKm,
    Duration? estimatedDuration,
  }) {
    return RouteData(
      id: id ?? this.id,
      points: points ?? this.points,
      options: options ?? this.options,
      label: label ?? this.label,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}

class RouteLayer extends StatelessWidget {
  final List<RouteData> routes;
  final bool showBorder;
  final bool isInteractive;

  const RouteLayer({
    super.key,
    required this.routes,
    this.showBorder = true,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];

    for (final route in routes) {
      if (route.points.isEmpty) continue;

      final polylinePoints = route.points;
      final opts = route.options;

      if (showBorder && opts.borderWidth > 0 && opts.borderColor != null) {
        polylines.add(
          Polyline(
            points: polylinePoints,
            color: opts.borderColor!,
            strokeWidth: opts.strokeWidth + (opts.borderWidth * 2),
          ),
        );
      }

      polylines.add(
        Polyline(
          points: polylinePoints,
          color: opts.color,
          strokeWidth: opts.strokeWidth,
        ),
      );
    }

    return Stack(
      children: polylines
          .map((polyline) => PolylineLayer(polylines: [polyline]))
          .toList(),
    );
  }
}

class RouteLayerWidget extends StatelessWidget {
  final List<RouteData> routes;
  final bool useStack;

  const RouteLayerWidget({
    super.key,
    required this.routes,
    this.useStack = true,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();

    final polylines = <Polyline>[];

    for (final route in routes) {
      if (route.points.length < 2) continue;

      final opts = route.options;

      if (opts.borderWidth > 0 && opts.borderColor != null) {
        polylines.add(
          Polyline(
            points: route.points,
            color: opts.borderColor!,
            strokeWidth: opts.strokeWidth + (opts.borderWidth * 2),
          ),
        );
      }

      polylines.add(
        Polyline(
          points: route.points,
          color: opts.color,
          strokeWidth: opts.strokeWidth,
        ),
      );
    }

    if (polylines.isEmpty) return const SizedBox.shrink();

    return PolylineLayer(polylines: polylines);
  }
}

class AnimatedRouteLayer extends StatelessWidget {
  final List<RouteData> routes;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedRouteLayer({
    super.key,
    required this.routes,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: animationDuration,
      curve: animationCurve,
      builder: (context, value, child) {
        final animatedRoutes = routes.map((route) {
          final animatedPoints = _interpolatePoints(route.points, value);
          return route.copyWith(points: animatedPoints);
        }).toList();

        return RouteLayerWidget(routes: animatedRoutes);
      },
    );
  }

  List<LatLng> _interpolatePoints(List<LatLng> points, double t) {
    if (points.length < 2 || t >= 1.0) return points;

    final totalSegments = points.length - 1;
    final maxPoints = (totalSegments * t).ceil() + 1;
    final result = <LatLng>[points.first];

    for (var i = 0; i < totalSegments && result.length < maxPoints; i++) {
      final start = points[i];
      final end = points[i + 1];
      final segmentT = (maxPoints - 1 - result.length) / (totalSegments - i);

      if (segmentT > 0) {
        result.add(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * segmentT,
            start.longitude + (end.longitude - start.longitude) * segmentT,
          ),
        );
      }

      if (result.length < maxPoints) {
        result.add(end);
      }
    }

    return result;
  }
}

extension RouteDataExtension on RouteData {
  double calculateDistance() {
    if (points.length < 2) return 0;

    const distance = Distance();
    double total = 0;

    for (var i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, points[i], points[i + 1]);
    }

    return total;
  }

  Duration? calculateDuration({double speedKmH = 40}) {
    final distance = calculateDistance();
    if (distance <= 0) return null;

    final hours = distance / speedKmH;
    return Duration(minutes: (hours * 60).round());
  }
}
