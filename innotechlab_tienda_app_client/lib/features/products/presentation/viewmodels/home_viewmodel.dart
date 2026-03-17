import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/error/error_logger.dart';
import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/features/products/domain/models/location_hour.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── State ──────────────────────────────────────────────────────────────────

class HomeState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? locationMessage;
  final List<Product> products;
  final List<ShopDistance> nearbyShops;
  final Shop? selectedShop;
  final double? userLatitude;
  final double? userLongitude;
  final List<LocationHour> selectedShopHours;
  final bool isLoadingHours;

  const HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.locationMessage,
    this.products = const [],
    this.nearbyShops = const [],
    this.selectedShop,
    this.userLatitude,
    this.userLongitude,
    this.selectedShopHours = const [],
    this.isLoadingHours = false,
  });

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? locationMessage,
    List<Product>? products,
    List<ShopDistance>? nearbyShops,
    Shop? selectedShop,
    double? userLatitude,
    double? userLongitude,
    List<LocationHour>? selectedShopHours,
    bool? isLoadingHours,
    bool clearError = false,
    bool clearSelectedShop = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      locationMessage: locationMessage ?? this.locationMessage,
      products: products ?? this.products,
      nearbyShops: nearbyShops ?? this.nearbyShops,
      selectedShop: clearSelectedShop
          ? null
          : selectedShop ?? this.selectedShop,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      selectedShopHours: clearSelectedShop
          ? const []
          : selectedShopHours ?? this.selectedShopHours,
      isLoadingHours: isLoadingHours ?? this.isLoadingHours,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    locationMessage,
    products,
    nearbyShops,
    selectedShop,
    userLatitude,
    userLongitude,
    selectedShopHours,
    isLoadingHours,
  ];
}

// ── Providers ──────────────────────────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(
    Supabase.instance.client,
    ref.watch(locationServiceProvider),
  );
});

// ── Notifier ───────────────────────────────────────────────────────────────

class HomeNotifier extends StateNotifier<HomeState> {
  final SupabaseClient _supabase;
  final LocationService _locationService;
  late String _userId;
  StreamSubscription<AuthState>? _authSub;
  Timer? _pollingTimer;

  HomeNotifier(this._supabase, this._locationService)
    : super(const HomeState()) {
    _userId = _supabase.auth.currentUser?.id ?? 'anonymous';

    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        _userId = data.session?.user.id ?? 'anonymous';
        initialize();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _userId = 'anonymous';
        state = state.copyWith(nearbyShops: [], products: []);
      }
    });

    if (_supabase.auth.currentUser != null) initialize();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshShopStatus();
    });
  }

  Future<void> _refreshShopStatus() async {
    if (state.selectedShop == null) return;
    try {
      final location = await _locationService.getCurrentPosition(
        accuracy: LocationAccuracy.low,
        timeout: const Duration(seconds: 5),
        maxRetries: 1,
      );
      final nearbyShops = await _fetchNearbyShops(location);

      final updatedShop = nearbyShops.firstWhere(
        (sd) => sd.shop.id == state.selectedShop!.id,
        orElse: () => ShopDistance(shop: state.selectedShop!, distanceKm: 0),
      );

      state = state.copyWith(
        nearbyShops: nearbyShops,
        selectedShop: updatedShop.shop,
      );
    } catch (_) {
      // Silently fail on polling errors
    }
  }

  Future<void> loadShopHours(String locationId) async {
    state = state.copyWith(isLoadingHours: true);
    try {
      final response = await _supabase.rpc(
        'get_location_hours',
        params: {'p_location_id': locationId},
      );

      final hoursJson = response as List<dynamic>?;
      if (hoursJson != null) {
        final hours = hoursJson
            .map((h) => LocationHour.fromJson(h as Map<String, dynamic>))
            .toList();
        state = state.copyWith(selectedShopHours: hours, isLoadingHours: false);
      } else {
        state = state.copyWith(
          selectedShopHours: const [],
          isLoadingHours: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        selectedShopHours: const [],
        isLoadingHours: false,
      );
    }
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final location = await _locationService.getCurrentPosition(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );

      final nearbyShops = await _fetchNearbyShops(location);

      if (nearbyShops.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          products: const [],
          nearbyShops: const [],
          errorMessage:
              'No hay comercios cercanos. Ajusta tu zona o cambia dirección.',
          clearSelectedShop: true,
        );
        return;
      }

      final activeShop = nearbyShops.first.shop;
      final catalog = await _fetchCatalog(activeShop.slug);

      state = state.copyWith(
        isLoading: false,
        nearbyShops: nearbyShops,
        selectedShop: activeShop,
        products: catalog,
        userLatitude: location.latitude,
        userLongitude: location.longitude,
        locationMessage:
            'Comercios cercanos a ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
      );
    } on LocationException catch (e) {
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.location,
        action: ErrorAction.getLocation,
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: _locationErrorMessage(e),
      );
    } catch (e, st) {
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.home,
        action: ErrorAction.loadShops,
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Error al cargar los comercios. Verifica tu conexión e intenta de nuevo.',
      );
    }
  }

  Future<void> selectShop(Shop shop) async {
    _startPolling();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedShop: shop,
      selectedShopHours: const [],
    );
    try {
      final catalog = await _fetchCatalog(shop.slug);
      await loadShopHours(shop.id);
      state = state.copyWith(isLoading: false, products: catalog);
    } catch (e, st) {
      await errorLogger.logCaughtError(
        userId: _userId,
        module: ErrorModule.home,
        action: ErrorAction.loadProducts,
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar los productos.',
      );
    }
  }

  void clearSelectedShop() {
    _pollingTimer?.cancel();
    state = state.copyWith(clearSelectedShop: true, products: const []);
  }

  Future<void> refreshNearbyShops() => initialize();

  // ── Private ──────────────────────────────────────────────────────────────

  Future<List<ShopDistance>> _fetchNearbyShops(LocationResult location) async {
    final response = await _supabase.rpc(
      'find_nearby_locations',
      params: {
        'p_lat': location.latitude,
        'p_lng': location.longitude,
        'p_radius_km': 10.0,
      },
    );

    final shopsJson = response as List<dynamic>?;
    if (shopsJson == null || shopsJson.isEmpty) return [];

    final seenOrganizationIds = <String>{};
    final shopsWithCoverage = <ShopDistance>[];

    for (final raw in shopsJson) {
      final map = raw as Map<String, dynamic>;
      final organizationId = map['organization_id'] as String?;

      // Skip if organization ID is null or already seen (deduplication)
      if (organizationId == null ||
          seenOrganizationIds.contains(organizationId)) {
        continue;
      }
      seenOrganizationIds.add(organizationId);

      final shop = Shop(
        id: map['id'] as String,
        name: (map['name'] ?? '') as String,
        slug: (map['organization_slug'] ?? '') as String,
        logoUrl: (map['brand_logo_url'] ?? map['image_url'] ?? '') as String,
        address: (map['address_line1'] ?? '') as String,
        schedule: map['status_text'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        serviceRadiusKm: (map['distance_km'] as num?)?.toDouble(),
        productIds: const [],
        city: '',
        isOpen: map['is_open'] as bool? ?? false,
        statusText: map['status_text'] as String?,
        deliveryStatus: Shop.parseDeliveryStatus(
          map['delivery_status'] as String?,
        ),
        pickupStatus: Shop.parseDeliveryStatus(map['pickup_status'] as String?),
        organizationName: map['organization_name'] as String?,
      );
      final distance = (map['distance_km'] as num?)?.toDouble() ?? 0;
      shopsWithCoverage.add(ShopDistance(shop: shop, distanceKm: distance));
    }

    shopsWithCoverage.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // Client-side radius filtering as backup (match cf-re-sites default)
    const maxRadius = 10.0;
    shopsWithCoverage.removeWhere(
      (shopDistance) => shopDistance.distanceKm > maxRadius,
    );

    return shopsWithCoverage;
  }

  Future<List<Product>> _fetchCatalog(String shopSlug) async {
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
        categoryId: (map['categoryId'] ?? '') as String,
      );
    }).toList();
  }

  String _locationErrorMessage(LocationException e) {
    switch (e.type) {
      case LocationErrorType.permissionDenied:
        return 'Se requiere acceso a tu ubicación. Habilita el permiso.';
      case LocationErrorType.permissionDeniedForever:
        return 'Permiso bloqueado. Habilítalo en configuración de la app.';
      case LocationErrorType.serviceDisabled:
        return 'Servicio de ubicación desactivado. Habilítalo en tu dispositivo.';
      case LocationErrorType.timeout:
        return 'Tiempo de espera agotado. Intenta de nuevo.';
      default:
        return e.message.isNotEmpty ? e.message : 'Error al obtener ubicación.';
    }
  }
}
