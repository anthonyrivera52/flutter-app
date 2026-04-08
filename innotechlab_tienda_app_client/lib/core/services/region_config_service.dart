import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'app_config_service.dart';

class RegionConfigService {
  static const String _storageKey = 'selected_country_code';

  static const Map<String, RegionConfig> southAmerica = {
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

  static RegionConfig get defaultConfig => southAmerica['CO']!;

  static bool isSupportedCountry(String countryCode) {
    return southAmerica.containsKey(countryCode);
  }

  static RegionConfig getConfig(String countryCode) {
    return southAmerica[countryCode] ?? defaultConfig;
  }

  static Future<String?> getSavedCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
  }

  static Future<void> saveCountryCode(String countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, countryCode);
  }

  static Future<RegionConfig> getConfigFromStorage() async {
    final countryCode = await getSavedCountryCode();
    if (countryCode != null && southAmerica.containsKey(countryCode)) {
      return southAmerica[countryCode]!;
    }
    return defaultConfig;
  }

  static Future<String?> detectCountryFromGPS() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 10));

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode;
      }
    } catch (e) {
      // Silent fail - return null
    }
    return null;
  }

  static Future<RegionConfig?> getConfigFromGPS() async {
    final countryCode = await detectCountryFromGPS();
    if (countryCode != null && southAmerica.containsKey(countryCode)) {
      return southAmerica[countryCode];
    }
    return null;
  }
}
