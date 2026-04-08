import 'package:equatable/equatable.dart';

class RegionConfig extends Equatable {
  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String currencySymbol;
  final int decimalDigits;

  const RegionConfig({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.decimalDigits,
  });

  factory RegionConfig.fromJson(Map<String, dynamic> json) {
    return RegionConfig(
      countryCode: json['country_code'] as String? ?? 'CO',
      countryName: json['country_name'] as String? ?? 'Colombia',
      currencyCode: json['currency_code'] as String? ?? 'COP',
      currencySymbol: json['currency_symbol'] as String? ?? r'$',
      decimalDigits: json['decimal_digits'] as int? ?? 0,
    );
  }

  String formatPrice(double price) {
    final formatted = decimalDigits == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(decimalDigits);
    return '$currencySymbol$formatted';
  }

  @override
  List<Object?> get props => [
    countryCode,
    countryName,
    currencyCode,
    currencySymbol,
    decimalDigits,
  ];

  static const RegionConfig defaultColombia = RegionConfig(
    countryCode: 'CO',
    countryName: 'Colombia',
    currencyCode: 'COP',
    currencySymbol: r'$',
    decimalDigits: 0,
  );
}

class AppCountryConfig extends Equatable {
  final String countryCode;
  final String currencyCode;
  final double ivaPercentage;
  final double commerceFeeAmount;
  final String commerceFeeLabel;
  final bool isActive;
  final String countryName;
  final String currencySymbol;
  final int decimalDigits;

  const AppCountryConfig({
    required this.countryCode,
    required this.currencyCode,
    required this.ivaPercentage,
    required this.commerceFeeAmount,
    required this.commerceFeeLabel,
    this.isActive = true,
    this.countryName = 'Colombia',
    this.currencySymbol = r'$',
    this.decimalDigits = 0,
  });

  factory AppCountryConfig.fromJson(Map<String, dynamic> json) {
    return AppCountryConfig(
      countryCode: json['country_code'] as String? ?? 'CO',
      currencyCode: json['currency_code'] as String? ?? 'COP',
      ivaPercentage: (json['iva_percentage'] as num?)?.toDouble() ?? 19.0,
      commerceFeeAmount:
          (json['commerce_fee_amount'] as num?)?.toDouble() ?? 0.0,
      commerceFeeLabel:
          json['commerce_fee_label'] as String? ?? 'Costo de uso de la app',
      isActive: json['is_active'] as bool? ?? true,
      countryName: json['country_name'] as String? ?? 'Colombia',
      currencySymbol: json['currency_symbol'] as String? ?? r'$',
      decimalDigits: json['decimal_digits'] as int? ?? 0,
    );
  }

  String formatPrice(double price) {
    final formatted = decimalDigits == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(decimalDigits);
    return '$currencySymbol$formatted';
  }

  RegionConfig toRegionConfig() {
    return RegionConfig(
      countryCode: countryCode,
      countryName: countryName,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      decimalDigits: decimalDigits,
    );
  }

  @override
  List<Object?> get props => [
    countryCode,
    currencyCode,
    ivaPercentage,
    commerceFeeAmount,
    commerceFeeLabel,
    isActive,
    countryName,
    currencySymbol,
    decimalDigits,
  ];
}
