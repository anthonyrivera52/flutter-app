class PaymentConstants {
  PaymentConstants._();

  static const String kushkiBaseUrlSandbox = 'https://api-uat.kushkipagos.com';
  static const String kushkiBaseUrlProduction = 'https://api.kushkipagos.com';

  static const String kushkiJsSandbox =
      'https://cdn.kushkipagos.com/kushki.min.js';
  static const String kushkiJsProduction =
      'https://cdn.kushkipagos.com/kushki.min.js';

  static const Duration tokenExpiration = Duration(minutes: 15);
  static const Duration requestTimeout = Duration(seconds: 30);

  static const List<String> supportedCardBrands = [
    'visa',
    'mastercard',
    'amex',
    'discover',
    'diners',
    'jcb',
  ];

  static const Map<String, String> cardBrandNames = {
    'visa': 'Visa',
    'mastercard': 'Mastercard',
    'amex': 'American Express',
    'discover': 'Discover',
    'diners': 'Diners Club',
    'jcb': 'JCB',
  };
}

class PaymentStatus {
  PaymentStatus._();

  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String paid = 'paid';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
  static const String partiallyRefunded = 'partially_refunded';
}

class PaymentMethod {
  PaymentMethod._();

  static const String cash = 'cash';
  static const String card = 'card';
}
