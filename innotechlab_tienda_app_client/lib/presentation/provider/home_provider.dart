import 'package:geolocator/geolocator.dart';
import 'package:flutter_app/core/error/error_logger.dart';
import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/shop.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/home_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for HomeNotifier - uses LocationService abstraction
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final supabase = Supabase.instance.client;
  final locationService = ref.watch(locationServiceProvider);
  return HomeNotifier(supabase, locationService)..initialize();
});

class HomeNotifier extends StateNotifier<HomeState> {
  final SupabaseClient _supabase;
  final LocationService _locationService;
  final String _userId;

  HomeNotifier(this._supabase, this._locationService)
      : _userId = _supabase.auth.currentUser?.id ?? 'anonymous',
        super(const HomeState());

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Use the abstracted location service
      final location = await _locationService.getCurrentPosition(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );

      final nearbyShops = await _resolveNearbyShopsFromApi(location);

      if (nearbyShops.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          products: const [],
          nearbyShops: const [],
          errorMessage: 'No hay comercios cercanos para tu ubicación. Ajusta tu zona o cambia dirección.',
          clearSelectedShop: true,
        );
        return;
      }

      final activeShop = nearbyShops.first.shop;
      final catalog = await _getCatalogForShop(activeShop.id);

      state = state.copyWith(
        isLoading: false,
        nearbyShops: nearbyShops,
        selectedShop: activeShop,
        products: catalog,
        locationMessage:
            'Mostrando comercios cercanos a ${_formatCoordinate(location.latitude)}, ${_formatCoordinate(location.longitude)}',
      );
    } on LocationException catch (e) {
      // Handle location-specific errors with user-friendly messages
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.location,
        action: ErrorAction.getLocation,
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e, stackTrace) {
      // Log error and show error state - no mock fallback
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.home,
        action: ErrorAction.loadShops,
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar los comercios. Por favor, verifica tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Format coordinate for display
  String _formatCoordinate(double value) {
    return value.toStringAsFixed(4);
  }

  Future<void> selectShop(Shop shop) async {
    state = state.copyWith(isLoading: true, clearError: true, selectedShop: shop);
    try {
      final catalog = await _getCatalogForShop(shop.id);
      state = state.copyWith(
        isLoading: false,
        selectedShop: shop,
        products: catalog,
      );
    } catch (e, stackTrace) {
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.home,
        action: ErrorAction.loadProducts,
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar los productos. Por favor, intenta de nuevo.',
      );
    }
  }

  void clearSelectedShop() {
    state = state.copyWith(clearSelectedShop: true, products: const []);
  }

  Future<void> refreshNearbyShops() async {
    await initialize();
  }

  Future<List<ShopDistance>> _resolveNearbyShopsFromApi(LocationResult location) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-nearby-shops',
        body: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radiusKm': 12,
        },
      );

      final shopsJson = (response.data['shops'] as List<dynamic>? ?? const []);
      if (shopsJson.isEmpty) return [];

      return shopsJson.map((raw) {
        final map = raw as Map<String, dynamic>;
        final shop = Shop(
          id: map['id'] as String,
          name: (map['name'] ?? '') as String,
          logoUrl: (map['logoUrl'] ?? '') as String,
          address: (map['address'] ?? '') as String,
          schedule: (map['schedule'] ?? '') as String,
          latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
          serviceRadiusKm: (map['serviceRadiusKm'] as num?)?.toDouble() ?? 0,
          productIds: const [],
        );

        // Calculate distance from user location
        final distance = _locationService.calculateDistance(
          location.latitude,
          location.longitude,
          shop.latitude,
          shop.longitude,
        );

        return ShopDistance(
          shop: shop,
          distanceKm: distance,
        );
      }).toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } catch (e, stackTrace) {
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.home,
        action: ErrorAction.loadShops,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Product>> _getCatalogForShop(String shopId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-catalog',
        body: {'shopId': shopId},
      );

      final productsJson = (response.data['products'] as List<dynamic>? ?? const []);
      return productsJson.map((raw) {
        final map = raw as Map<String, dynamic>;
        return Product(
          id: map['id'] as String,
          name: (map['name'] ?? '') as String,
          description: (map['description'] ?? '') as String,
          price: (map['price'] as num?)?.toDouble() ?? 0,
          imageUrl: (map['image_url'] ?? '') as String,
          unit: (map['unit'] ?? 'unidad') as String,
          categoryId: (map['category_id'] ?? '') as String,
          discountedPrice: (map['discounted_price'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (e, stackTrace) {
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.products,
        action: ErrorAction.loadProducts,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
