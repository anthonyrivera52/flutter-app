import 'package:equatable/equatable.dart';

enum PaymentMethodType { cash, online }

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
  final String? gatewayTransactionId;
  final double amount;
  final String currency;
  final double refundAmount;
  final String? refundReason;
  final DateTime? refundedAt;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.saleId,
    required this.paymentMethod,
    required this.paymentStatus,
    this.gatewayTransactionId,
    required this.amount,
    this.currency = 'COP',
    this.refundAmount = 0,
    this.refundReason,
    this.refundedAt,
    required this.createdAt,
  });

  bool get isPaid => paymentStatus == PaymentStatusType.paid;
  bool get isFailed => paymentStatus == PaymentStatusType.failed;
  bool get isRefunded => paymentStatus == PaymentStatusType.refunded;
  bool get isOnline => paymentMethod == PaymentMethodType.online;
  bool get isCash => paymentMethod == PaymentMethodType.cash;

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      paymentMethod: json['payment_method'] == 'online'
          ? PaymentMethodType.online
          : PaymentMethodType.cash,
      paymentStatus: _parseStatus(json['payment_status'] as String),
      gatewayTransactionId: json['gateway_transaction_id'] as String?,
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'] as String? ?? 'COP',
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
    gatewayTransactionId,
    amount,
    currency,
    refundAmount,
    refundReason,
    refundedAt,
    createdAt,
  ];
}

class PaymentResult extends Equatable {
  final bool success;
  final String? transactionId;
  final String? gatewayTransactionId;
  final PaymentStatusType? paymentStatus;
  final String? error;
  final String? errorCode;
  final PaymentMethodType? paymentMethod;
  final double? amount;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.gatewayTransactionId,
    this.paymentStatus,
    this.error,
    this.errorCode,
    this.paymentMethod,
    this.amount,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    PaymentMethodType? method;
    if (json['paymentMethod'] == 'online') {
      method = PaymentMethodType.online;
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
      gatewayTransactionId: json['gatewayTransactionId'] as String?,
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
    gatewayTransactionId,
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
  final double? refundAmount;
  final double? totalRefunded;
  final bool? isFullyRefunded;
  final String? error;

  const RefundResult({
    required this.success,
    this.transactionId,
    this.refundAmount,
    this.totalRefunded,
    this.isFullyRefunded,
    this.error,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      success: json['success'] as bool? ?? false,
      transactionId: json['transactionId'] as String?,
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
    refundAmount,
    totalRefunded,
    isFullyRefunded,
    error,
  ];
}
