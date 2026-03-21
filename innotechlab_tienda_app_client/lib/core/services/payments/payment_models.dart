import 'package:equatable/equatable.dart';

enum PaymentMethodType { cash, card }

enum PaymentStatusType {
  pending,
  processing,
  paid,
  failed,
  refunded,
  partiallyRefunded,
}

class PaymentTransaction extends Equatable {
  final String id;
  final String saleId;
  final PaymentMethodType paymentMethod;
  final PaymentStatusType paymentStatus;
  final String? kushkiTransactionId;
  final double amount;
  final String currency;
  final String? cardLastFour;
  final String? cardBrand;
  final double refundAmount;
  final String? refundReason;
  final DateTime? refundedAt;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.saleId,
    required this.paymentMethod,
    required this.paymentStatus,
    this.kushkiTransactionId,
    required this.amount,
    this.currency = 'USD',
    this.cardLastFour,
    this.cardBrand,
    this.refundAmount = 0,
    this.refundReason,
    this.refundedAt,
    required this.createdAt,
  });

  bool get isPaid => paymentStatus == PaymentStatusType.paid;
  bool get isFailed => paymentStatus == PaymentStatusType.failed;
  bool get isRefunded => paymentStatus == PaymentStatusType.refunded;
  bool get isCard => paymentMethod == PaymentMethodType.card;
  bool get isCash => paymentMethod == PaymentMethodType.cash;

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      paymentMethod: json['payment_method'] == 'card'
          ? PaymentMethodType.card
          : PaymentMethodType.cash,
      paymentStatus: _parseStatus(json['payment_status'] as String),
      kushkiTransactionId: json['kushki_transaction_id'] as String?,
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'] as String? ?? 'USD',
      cardLastFour: json['card_last_four'] as String?,
      cardBrand: json['card_brand'] as String?,
      refundAmount: double.parse((json['refund_amount'] ?? '0').toString()),
      refundReason: json['refund_reason'] as String?,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static PaymentStatusType _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatusType.pending;
      case 'processing':
        return PaymentStatusType.processing;
      case 'paid':
        return PaymentStatusType.paid;
      case 'failed':
        return PaymentStatusType.failed;
      case 'refunded':
        return PaymentStatusType.refunded;
      case 'partially_refunded':
        return PaymentStatusType.partiallyRefunded;
      default:
        return PaymentStatusType.pending;
    }
  }

  @override
  List<Object?> get props => [
    id,
    saleId,
    paymentMethod,
    paymentStatus,
    kushkiTransactionId,
    amount,
    currency,
    cardLastFour,
    cardBrand,
    refundAmount,
    refundReason,
    refundedAt,
    createdAt,
  ];
}

class CardData extends Equatable {
  final String cardNumber;
  final String cardholderName;
  final String cvv;
  final String expiryMonth;
  final String expiryYear;

  const CardData({
    required this.cardNumber,
    required this.cardholderName,
    required this.cvv,
    required this.expiryMonth,
    required this.expiryYear,
  });

  String get lastFour =>
      cardNumber.replaceAll(' ', '').substring(cardNumber.length - 4);

  String get brand {
    final number = cardNumber.replaceAll(' ', '');
    if (number.startsWith('4')) return 'visa';
    if (number.startsWith('5')) return 'mastercard';
    if (number.startsWith('34') || number.startsWith('37')) return 'amex';
    if (number.startsWith('6011')) return 'discover';
    return 'unknown';
  }

  bool get isValid {
    return cardNumber.replaceAll(' ', '').length >= 15 &&
        cardholderName.isNotEmpty &&
        cvv.length >= 3 &&
        _isValidExpiry();
  }

  bool _isValidExpiry() {
    final now = DateTime.now();
    final year = int.tryParse('20$expiryYear') ?? 0;
    final month = int.tryParse(expiryMonth) ?? 0;

    if (month < 1 || month > 12) return false;
    if (year < now.year) return false;
    if (year == now.year && month < now.month) return false;

    return true;
  }

  @override
  List<Object?> get props => [
    cardNumber,
    cardholderName,
    cvv,
    expiryMonth,
    expiryYear,
  ];
}

class PaymentResult extends Equatable {
  final bool success;
  final String? transactionId;
  final String? kushkiTransactionId;
  final PaymentStatusType? paymentStatus;
  final String? error;
  final String? errorCode;
  final PaymentMethodType? paymentMethod;
  final double? amount;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.kushkiTransactionId,
    this.paymentStatus,
    this.error,
    this.errorCode,
    this.paymentMethod,
    this.amount,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    PaymentMethodType? method;
    if (json['paymentMethod'] == 'card') {
      method = PaymentMethodType.card;
    } else if (json['paymentMethod'] == 'cash') {
      method = PaymentMethodType.cash;
    }

    PaymentStatusType? status;
    final statusStr = json['paymentStatus'] as String?;
    if (statusStr != null) {
      switch (statusStr) {
        case 'paid':
          status = PaymentStatusType.paid;
          break;
        case 'failed':
          status = PaymentStatusType.failed;
          break;
        case 'processing':
          status = PaymentStatusType.processing;
          break;
        default:
          status = PaymentStatusType.pending;
      }
    }

    return PaymentResult(
      success: json['success'] as bool? ?? false,
      transactionId: json['transactionId'] as String?,
      kushkiTransactionId: json['kushkiTransactionId'] as String?,
      paymentStatus: status,
      error: json['error'] as String?,
      errorCode: json['errorCode'] as String?,
      paymentMethod: method,
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : null,
    );
  }

  factory PaymentResult.failed(String error, {String? errorCode}) {
    return PaymentResult(success: false, error: error, errorCode: errorCode);
  }

  @override
  List<Object?> get props => [
    success,
    transactionId,
    kushkiTransactionId,
    paymentStatus,
    error,
    errorCode,
    paymentMethod,
    amount,
  ];
}

class RefundResult extends Equatable {
  final bool success;
  final String? transactionId;
  final String? kushkiRefundId;
  final double? refundAmount;
  final double? totalRefunded;
  final bool? isFullyRefunded;
  final String? error;

  const RefundResult({
    required this.success,
    this.transactionId,
    this.kushkiRefundId,
    this.refundAmount,
    this.totalRefunded,
    this.isFullyRefunded,
    this.error,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      success: json['success'] as bool? ?? false,
      transactionId: json['transactionId'] as String?,
      kushkiRefundId: json['kushkiRefundId'] as String?,
      refundAmount: json['refundAmount'] != null
          ? double.parse(json['refundAmount'].toString())
          : null,
      totalRefunded: json['totalRefunded'] != null
          ? double.parse(json['totalRefunded'].toString())
          : null,
      isFullyRefunded: json['isFullyRefunded'] as bool?,
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    success,
    transactionId,
    kushkiRefundId,
    refundAmount,
    totalRefunded,
    isFullyRefunded,
    error,
  ];
}
