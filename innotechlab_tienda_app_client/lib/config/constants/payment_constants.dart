class PaymentConstants {
  PaymentConstants._();

  static const String boldJsUrl =
      'https://checkout.bold.co/library/boldPaymentButton.js';

  static const Duration requestTimeout = Duration(seconds: 30);
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
  static const String online = 'online';
}
