import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_config_provider.dart';
import '../../core/services/app_config_service.dart';

class RegionState {
  final RegionConfig config;
  final bool isLoading;
  final bool hasCheckedGPS;
  final RegionConfig? gpsDetectedConfig;
  final String? errorMessage;

  const RegionState({
    required this.config,
    this.isLoading = false,
    this.hasCheckedGPS = false,
    this.gpsDetectedConfig,
    this.errorMessage,
  });

  RegionState copyWith({
    RegionConfig? config,
    bool? isLoading,
    bool? hasCheckedGPS,
    RegionConfig? gpsDetectedConfig,
    String? errorMessage,
    bool clearGPSConfig = false,
  }) {
    return RegionState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      hasCheckedGPS: hasCheckedGPS ?? this.hasCheckedGPS,
      gpsDetectedConfig: clearGPSConfig
          ? null
          : (gpsDetectedConfig ?? this.gpsDetectedConfig),
      errorMessage: errorMessage,
    );
  }

  bool get shouldShowCountryChangeModal {
    if (!hasCheckedGPS || gpsDetectedConfig == null) return false;
    return gpsDetectedConfig!.countryCode != config.countryCode;
  }
}

class RegionNotifier extends StateNotifier<RegionState> {
  final Ref _ref;

  RegionNotifier(this._ref)
    : super(RegionState(config: RegionConfig.defaultColombia)) {
    _syncFromAppConfig();
  }

  void _syncFromAppConfig() {
    final appConfig = _ref.read(appConfigProvider);
    state = state.copyWith(
      config: appConfig.regionConfig,
      isLoading: appConfig.isLoading,
    );
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    _syncFromAppConfig();
  }

  Future<void> checkAndUpdateFromGPS() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      isLoading: false,
      hasCheckedGPS: true,
      gpsDetectedConfig: null,
    );
  }

  Future<void> updateCountry(String countryCode) async {
    _ref.read(appConfigProvider.notifier).setCountryCode(countryCode);
    final appConfig = _ref.read(appConfigProvider);
    state = state.copyWith(
      config: appConfig.regionConfig,
      clearGPSConfig: true,
    );
  }

  Future<void> acceptGPSCountry() async {
    if (state.gpsDetectedConfig != null) {
      _ref
          .read(appConfigProvider.notifier)
          .setCountryCode(state.gpsDetectedConfig!.countryCode);
      final appConfig = _ref.read(appConfigProvider);
      state = state.copyWith(
        config: appConfig.regionConfig,
        clearGPSConfig: true,
      );
    }
  }

  Future<void> keepCurrentCountry() async {
    state = state.copyWith(clearGPSConfig: true);
  }
}

final regionProvider = StateNotifierProvider<RegionNotifier, RegionState>((
  ref,
) {
  return RegionNotifier(ref);
});

final currentRegionConfigProvider = Provider<RegionConfig>((ref) {
  final regionState = ref.watch(regionProvider);
  final appConfigState = ref.watch(appConfigProvider);

  if (appConfigState.regionConfig != RegionConfig.defaultColombia) {
    return appConfigState.regionConfig;
  }
  return regionState.config;
});
