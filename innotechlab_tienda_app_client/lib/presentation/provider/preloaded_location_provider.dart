import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user location preloaded during splash screen
/// so the home page map can render immediately without waiting for GPS.
final preloadedLocationProvider = StateProvider<LocationResult?>((ref) => null);
