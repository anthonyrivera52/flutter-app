import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/location/location_service.dart';
import '../../features/products/domain/models/shop_entity.dart';
import './location_provider.dart';

// Estado del polling
class ShopsPollingState {
  final List<ShopDistance> shops;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;

  const ShopsPollingState({
    this.shops = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdate,
  });

  ShopsPollingState copyWith({
    List<ShopDistance>? shops,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
    bool clearError = false,
  }) {
    return ShopsPollingState(
      shops: shops ?? this.shops,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  List<Object?> get props => [shops, isLoading, error, lastUpdate];
}

// Provider con polling automático
final shopsPollingProvider =
    StateNotifierProvider.autoDispose<ShopsPollingNotifier, ShopsPollingState>((
      ref,
    ) {
      final locationService = ref.watch(locationServiceProvider);
      return ShopsPollingNotifier(Supabase.instance.client, locationService);
    });

// Notifier con timer de polling
class ShopsPollingNotifier extends StateNotifier<ShopsPollingState> {
  final SupabaseClient _supabase;
  final LocationService _locationService;
  Timer? _pollingTimer;
  bool _isPollingStarted = false;

  ShopsPollingNotifier(this._supabase, this._locationService)
    : super(const ShopsPollingState()) {
    // Iniciar polling automáticamente al crear el notifier
    startPolling();
  }

  // Iniciar polling automático (se llama al crear el provider)
  void startPolling() {
    if (_isPollingStarted) return;

    _isPollingStarted = true;

    // Cargar datos inmediatamente
    _refreshShops();

    // Iniciar timer de 30 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshShops();
    });
  }

  // Detener polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingStarted = false;
  }

  // Refrescar comercios
  Future<void> _refreshShops() async {
    try {
      state = state.copyWith(isLoading: true);

      final location = await _locationService.getCurrentPosition(
        accuracy: LocationAccuracy.low,
        timeout: const Duration(seconds: 10),
        maxRetries: 1,
      );

      final response = await _supabase.rpc(
        'find_nearby_locations',
        params: {
          'p_lat': location.latitude,
          'p_lng': location.longitude,
          'p_radius_km': 10.0,
        },
      );

      final shopsJson = response as List<dynamic>?;
      if (shopsJson == null || shopsJson.isEmpty) {
        state = state.copyWith(
          shops: [],
          isLoading: false,
          error: null,
          lastUpdate: DateTime.now(),
        );
        return;
      }

      // Procesar y deduplicar comercios
      final seenOrganizationIds = <String>{};
      final shops = <ShopDistance>[];

      for (final raw in shopsJson) {
        final map = raw as Map<String, dynamic>;
        final organizationId = map['organization_id'] as String?;

        // Saltar si el ID de organización es nulo o ya fue visto
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
          pickupStatus: Shop.parseDeliveryStatus(
            map['pickup_status'] as String?,
          ),
          organizationName: map['organization_name'] as String?,
        );
        final distance = (map['distance_km'] as num?)?.toDouble() ?? 0;
        shops.add(ShopDistance(shop: shop, distanceKm: distance));
      }

      // Ordenar por distancia
      shops.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      // Filtrar por radio máximo (backup)
      shops.removeWhere((shopDistance) => shopDistance.distanceKm > 10.0);

      state = state.copyWith(
        shops: shops,
        isLoading: false,
        error: null,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastUpdate: DateTime.now(),
      );
    }
  }

  // Obtener comercio por ID
  ShopDistance? getShopById(String shopId) {
    return state.shops.firstWhere(
      (shopDistance) => shopDistance.shop.id == shopId,
      orElse: () => const ShopDistance(
        shop: Shop(
          id: '',
          name: '',
          slug: '',
          logoUrl: '',
          address: '',
          latitude: 0,
          longitude: 0,
          productIds: [],
        ),
        distanceKm: 0,
      ),
    );
  }

  // Verificar si un comercio está abierto
  bool isShopOpen(String shopId) {
    final shop = getShopById(shopId);
    return shop?.shop.isOpen ?? false;
  }

  // Limpiar recursos
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
