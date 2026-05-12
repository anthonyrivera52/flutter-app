import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/error/error_logger.dart';
import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/features/products/domain/models/category_entity.dart';
import 'package:flutter_app/features/products/domain/models/location_hour.dart';
import 'package:flutter_app/presentation/provider/preloaded_location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogResult {
  final List<Product> products;
  final List<Category> categories;
  CatalogResult({required this.products, required this.categories});
}

// ── State ──────────────────────────────────────────────────────────────────

class HomeState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? locationMessage;
  final List<Product> products;
  final List<Category> categories;
  final List<ShopDistance> nearbyShops;
  final List<ShopDistance> filteredNearbyShops;
  final String searchQuery;
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
    this.categories = const [],
    this.nearbyShops = const [],
    this.filteredNearbyShops = const [],
    this.searchQuery = '',
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
    List<Category>? categories,
    List<ShopDistance>? nearbyShops,
    List<ShopDistance>? filteredNearbyShops,
    String? searchQuery,
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
      categories: categories ?? this.categories,
      nearbyShops: nearbyShops ?? this.nearbyShops,
      filteredNearbyShops: filteredNearbyShops ?? this.filteredNearbyShops,
      searchQuery: searchQuery ?? this.searchQuery,
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
    categories,
    nearbyShops,
    filteredNearbyShops,
    searchQuery,
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
    ref,
  );
});

// ── Notifier ───────────────────────────────────────────────────────────────

class HomeNotifier extends StateNotifier<HomeState> {
  final SupabaseClient _supabase;
  final LocationService _locationService;
  final Ref _ref;
  late String _userId;
  StreamSubscription<AuthState>? _authSub;

  HomeNotifier(this._supabase, this._locationService, this._ref)
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
    super.dispose();
  }

  // Polling moved to shopsPollingProvider

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
      // Try preloaded location first (from splash screen)
      LocationResult location =
          _ref.read(preloadedLocationProvider) ??
          await _locationService.getCurrentPosition(
            accuracy: LocationAccuracy.high,
            timeout: const Duration(seconds: 15),
            maxRetries: 2,
          );

      state = state.copyWith(
        isLoading: false,
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
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedShop: shop,
      selectedShopHours: const [],
    );
    try {
      final catalog = await _fetchCatalog(shop);
      await loadShopHours(shop.id);
      state = state.copyWith(
        isLoading: false,
        products: catalog.products,
        categories: catalog.categories,
      );
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
    state = state.copyWith(
      clearSelectedShop: true,
      products: const [],
      categories: const [],
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilter();
  }

  void updateNearbyShops(List<ShopDistance> nearbyShops) {
    if (state.nearbyShops == nearbyShops) return;
    state = state.copyWith(nearbyShops: nearbyShops);
    _applyFilter();
  }

  void _applyFilter() {
    if (state.searchQuery.isEmpty) {
      state = state.copyWith(filteredNearbyShops: state.nearbyShops);
      return;
    }

    final query = state.searchQuery.toLowerCase();
    final filtered = state.nearbyShops.where((shopDistance) {
      final name = shopDistance.shop.name.toLowerCase();
      final orgName = (shopDistance.shop.organizationName ?? '').toLowerCase();
      return name.contains(query) || orgName.contains(query);
    }).toList();

    state = state.copyWith(filteredNearbyShops: filtered);
  }

  Future<void> refreshNearbyShops() => initialize();

  // ── Private ──────────────────────────────────────────────────────────────

  Future<CatalogResult> _fetchCatalog(Shop shop) async {
    final response = await _supabase.functions.invoke(
      'get-catalog',
      body: {'locationId': shop.id},
    );

    final productsJson =
        (response.data['products'] as List<dynamic>? ?? const []);
    final categoriesJson =
        (response.data['categories'] as List<dynamic>? ?? const []);

    final categories = categoriesJson.map((raw) {
      final map = raw as Map<String, dynamic>;
      return Category(
        id: map['id'] as String,
        name: map['name'] as String,
        imageUrl: map['image_url'] as String?,
      );
    }).toList();

final products = productsJson.map((raw) {
       final map = raw as Map<String, dynamic>;
       return Product(
         id: map['id'] as String,
         name: (map['name'] ?? '') as String,
         description: (map['description'] ?? '') as String,
         price: (map['price'] as num?)?.toDouble() ?? 0,
         imageUrl: (map['image_url'] ?? '') as String,
         unit: (map['unit'] ?? 'unidad') as String,
         categoryId: (map['category_id'] ?? '') as String,
         discountedPrice: null, // discounted_price NO existe en products — se calcula aparte
       );
     }).toList();

    return CatalogResult(products: products, categories: categories);
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
