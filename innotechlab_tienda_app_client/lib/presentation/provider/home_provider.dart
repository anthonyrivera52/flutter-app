import 'dart:async';
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
  return HomeNotifier(supabase, locationService);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final SupabaseClient _supabase;
  final LocationService _locationService;
  late String _userId;
  StreamSubscription<AuthState>? _authSubscription;

  HomeNotifier(this._supabase, this._locationService)
    : super(const HomeState()) {
    _userId = _supabase.auth.currentUser?.id ?? 'anonymous';

    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        _userId = data.session?.user.id ?? 'anonymous';
        initialize();
      } else if (event == AuthChangeEvent.signedOut) {
        _userId = 'anonymous';
        state = state.copyWith(nearbyShops: [], products: []);
        // Reset state or perform other cleanup if needed
      }
    });

    // If already authenticated, initialize
    if (_supabase.auth.currentUser != null) {
      initialize();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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
          errorMessage:
              'No hay comercios cercanos para tu ubicación. Ajusta tu zona o cambia dirección.',
          clearSelectedShop: true,
        );
        return;
      }

      final activeShop = nearbyShops.first.shop;
      final catalog = await _getCatalogForShop(activeShop.slug);

      state = state.copyWith(
        isLoading: false,
        nearbyShops: nearbyShops,
        selectedShop: activeShop,
        products: catalog,
        userLatitude: location.latitude,
        userLongitude: location.longitude,
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

      String userMessage;
      switch (e.type) {
        case LocationErrorType.permissionDenied:
          userMessage =
              'Se requiere acceso a tu ubicación para mostrar comercios cercanos. Por favor, habilita el permiso de ubicación.';
          break;
        case LocationErrorType.permissionDeniedForever:
          userMessage =
              'El permiso de ubicación está bloqueado. Por favor, habilítalo en la configuración de la app.';
          break;
        case LocationErrorType.serviceDisabled:
          userMessage =
              'El servicio de ubicación está desactivado. Por favor, habilítalo en tu dispositivo.';
          break;
        case LocationErrorType.timeout:
          userMessage =
              'La obtención de ubicación tardó demasiado. Por favor, intenta de nuevo.';
          break;
        default:
          userMessage = e.message.isNotEmpty
              ? e.message
              : 'Error al obtener tu ubicación. Por favor, intenta de nuevo.';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: userMessage,
        locationMessage: null,
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
        errorMessage:
            'Error al cargar los comercios. Por favor, verifica tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Format coordinate for display
  String _formatCoordinate(double value) {
    return value.toStringAsFixed(4);
  }

  Future<void> selectShop(Shop shop) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedShop: shop,
    );
    try {
      final catalog = await _getCatalogForShop(shop.slug);
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
        errorMessage:
            'Error al cargar los productos. Por favor, intenta de nuevo.',
      );
    }
  }

  void clearSelectedShop() {
    state = state.copyWith(clearSelectedShop: true, products: const []);
  }

  Future<void> refreshNearbyShops() async {
    await initialize();
  }

  Future<List<ShopDistance>> _resolveNearbyShopsFromApi(
    LocationResult location,
  ) async {
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
          slug: (map['slug'] ?? '') as String,
          logoUrl: (map['logoUrl'] ?? '') as String,
          address: (map['address'] ?? '') as String,
          schedule: (map['schedule'] ?? '') as String?,
          latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
          serviceRadiusKm: (map['serviceRadiusKm'] as num?)?.toDouble(),
          productIds: const [],
          city: (map['city'] as String?) ?? '',
        );

        // Calculate distance from user location
        final distance = _locationService.calculateDistance(
          location.latitude,
          location.longitude,
          shop.latitude,
          shop.longitude,
        );

        return ShopDistance(shop: shop, distanceKm: distance);
      }).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
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

  Future<List<Product>> _getCatalogForShop(String shopSlug) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-catalog',
        body: {'slug': shopSlug},
      );

      final productsJson =
          (response.data['products'] as List<dynamic>? ?? const []);
      return productsJson.map((raw) {
        final map = raw as Map<String, dynamic>;
        return Product(
          id: map['id'] as String,
          name: (map['name'] ?? '') as String,
          description: (map['description'] ?? '') as String,
          price: (map['price'] as num?)?.toDouble() ?? 0,
          imageUrl: (map['imageUrl'] ?? '') as String,
          unit: (map['unit'] ?? 'unidad') as String,
          categoryId: '',
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
