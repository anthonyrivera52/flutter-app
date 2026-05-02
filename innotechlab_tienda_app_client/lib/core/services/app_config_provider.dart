import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config_service.dart';

class AppConfigState {
  final AppCountryConfig? config;
  final RegionConfig regionConfig;
  final bool isLoading;
  final String? error;

  const AppConfigState({
    this.config,
    this.regionConfig = RegionConfig.defaultColombia,
    this.isLoading = false,
    this.error,
  });

  AppConfigState copyWith({
    AppCountryConfig? config,
    RegionConfig? regionConfig,
    bool? isLoading,
    String? error,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      regionConfig: regionConfig ?? this.regionConfig,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static AppConfigState get defaultColombia => AppConfigState(
    config: const AppCountryConfig(
      countryCode: 'CO',
      currencyCode: 'COP',
      ivaPercentage: 19.0,
      commerceFeeAmount: 2000.0,
      commerceFeeLabel: 'Costo de uso de la app',
      countryName: 'Colombia',
      currencySymbol: r'$',
      decimalDigits: 0,
    ),
    regionConfig: RegionConfig.defaultColombia,
  );
}

class AppConfigNotifier extends StateNotifier<AppConfigState> {
  final SupabaseClient _supabase;

  AppConfigNotifier(this._supabase) : super(AppConfigState.defaultColombia) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    state = state.copyWith(isLoading: true);

    try {
      final countryCode = _getStoredCountryCode();

      final regionResponse = await _supabase
          .from('app_region_config')
          .select()
          .eq('country_code', countryCode)
          .eq('is_active', true)
          .maybeSingle();

      RegionConfig regionConfig;
      if (regionResponse != null) {
        regionConfig = RegionConfig.fromJson(regionResponse);
      } else {
        regionConfig = _getHardcodedRegionConfig(countryCode);
      }

      final taxResponse = await _supabase
          .from('app_country_config')
          .select()
          .eq('country_code', countryCode)
          .eq('is_active', true)
          .maybeSingle();

      AppCountryConfig? config;
      if (taxResponse != null) {
        config = AppCountryConfig(
          countryCode: regionConfig.countryCode,
          countryName: regionConfig.countryName,
          currencyCode: regionConfig.currencyCode,
          currencySymbol: regionConfig.currencySymbol,
          decimalDigits: regionConfig.decimalDigits,
          ivaPercentage:
              (taxResponse['iva_percentage'] as num?)?.toDouble() ?? 19.0,
          commerceFeeAmount:
              (taxResponse['commerce_fee_amount'] as num?)?.toDouble() ?? 0.0,
          commerceFeeLabel:
              taxResponse['commerce_fee_label'] as String? ??
              'Costo de uso de la app',
          isActive: taxResponse['is_active'] as bool? ?? true,
        );
      }

      state = state.copyWith(
        config: config,
        regionConfig: regionConfig,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _getStoredCountryCode() {
    try {
      return 'CO';
    } catch (_) {
      return 'CO';
    }
  }

  RegionConfig _getHardcodedRegionConfig(String countryCode) {
    const Map<String, RegionConfig> fallback = {
      'CO': RegionConfig(
        countryCode: 'CO',
        countryName: 'Colombia',
        currencyCode: 'COP',
        currencySymbol: r'$',
        decimalDigits: 0,
      ),
      'AR': RegionConfig(
        countryCode: 'AR',
        countryName: 'Argentina',
        currencyCode: 'ARS',
        currencySymbol: r'$',
        decimalDigits: 2,
      ),
      'CL': RegionConfig(
        countryCode: 'CL',
        countryName: 'Chile',
        currencyCode: 'CLP',
        currencySymbol: r'$',
        decimalDigits: 0,
      ),
      'PE': RegionConfig(
        countryCode: 'PE',
        countryName: 'Perú',
        currencyCode: 'PEN',
        currencySymbol: 'S/',
        decimalDigits: 2,
      ),
      'BR': RegionConfig(
        countryCode: 'BR',
        countryName: 'Brasil',
        currencyCode: 'BRL',
        currencySymbol: r'R$',
        decimalDigits: 2,
      ),
      'UY': RegionConfig(
        countryCode: 'UY',
        countryName: 'Uruguay',
        currencyCode: 'UYU',
        currencySymbol: r'$',
        decimalDigits: 2,
      ),
      'BO': RegionConfig(
        countryCode: 'BO',
        countryName: 'Bolivia',
        currencyCode: 'BOB',
        currencySymbol: 'Bs.',
        decimalDigits: 2,
      ),
      'PY': RegionConfig(
        countryCode: 'PY',
        countryName: 'Paraguay',
        currencyCode: 'PYG',
        currencySymbol: '₲',
        decimalDigits: 0,
      ),
      'EC': RegionConfig(
        countryCode: 'EC',
        countryName: 'Ecuador',
        currencyCode: 'USD',
        currencySymbol: r'$',
        decimalDigits: 2,
      ),
    };
    return fallback[countryCode] ?? RegionConfig.defaultColombia;
  }

  Future<void> refresh() async {
    await _loadConfig();
  }

  void setCountryCode(String countryCode) {
    _loadConfigForCountry(countryCode);
  }

  Future<void> _loadConfigForCountry(String countryCode) async {
    state = state.copyWith(isLoading: true);

    try {
      final regionResponse = await _supabase
          .from('app_region_config')
          .select()
          .eq('country_code', countryCode)
          .eq('is_active', true)
          .maybeSingle();

      RegionConfig regionConfig;
      if (regionResponse != null) {
        regionConfig = RegionConfig.fromJson(regionResponse);
      } else {
        regionConfig = _getHardcodedRegionConfig(countryCode);
      }

      final taxResponse = await _supabase
          .from('app_country_config')
          .select()
          .eq('country_code', countryCode)
          .eq('is_active', true)
          .maybeSingle();

      AppCountryConfig? config;
      if (taxResponse != null) {
        config = AppCountryConfig(
          countryCode: regionConfig.countryCode,
          countryName: regionConfig.countryName,
          currencyCode: regionConfig.currencyCode,
          currencySymbol: regionConfig.currencySymbol,
          decimalDigits: regionConfig.decimalDigits,
          ivaPercentage:
              (taxResponse['iva_percentage'] as num?)?.toDouble() ?? 19.0,
          commerceFeeAmount:
              (taxResponse['commerce_fee_amount'] as num?)?.toDouble() ?? 0.0,
          commerceFeeLabel:
              taxResponse['commerce_fee_label'] as String? ??
              'Costo de uso de la app',
          isActive: taxResponse['is_active'] as bool? ?? true,
        );
      }

      state = state.copyWith(
        config: config,
        regionConfig: regionConfig,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfigState>((ref) {
      return AppConfigNotifier(Supabase.instance.client);
    });

final regionConfigProvider = Provider<RegionConfig>((ref) {
  final state = ref.watch(appConfigProvider);
  return state.regionConfig;
});

final ivaPercentageProvider = Provider<double>((ref) {
  return ref.watch(appConfigProvider).config?.ivaPercentage ?? 19.0;
});

final commerceFeeProvider = Provider<double>((ref) {
  return ref.watch(appConfigProvider).config?.commerceFeeAmount ?? 0.0;
});

final commerceFeeLabelProvider = Provider<String>((ref) {
  return ref.watch(appConfigProvider).config?.commerceFeeLabel ??
      'Costo de uso de la app';
});

final decimalDigitsProvider = Provider<int>((ref) {
  return ref.watch(appConfigProvider).regionConfig.decimalDigits;
});

final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(appConfigProvider).regionConfig.currencySymbol;
});
