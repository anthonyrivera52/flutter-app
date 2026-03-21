import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kushki_api_client.dart';
import 'payment_models.dart';
import 'payment_exceptions.dart';

final kushkiPaymentServiceProvider = Provider<KushkiPaymentService>((ref) {
  return KushkiPaymentService();
});

final paymentProcessingProvider =
    StateNotifierProvider<PaymentProcessingNotifier, PaymentProcessingState>((
      ref,
    ) {
      return PaymentProcessingNotifier(ref.watch(kushkiPaymentServiceProvider));
    });

class KushkiPaymentService {
  final KushkiApiClient _apiClient;

  KushkiPaymentService({KushkiApiClient? apiClient})
    : _apiClient = apiClient ?? KushkiApiClient();

  Future<PaymentResult> payWithCard({
    required String saleId,
    required CardData card,
    required double amount,
    required String currency,
  }) async {
    if (!card.isValid) {
      throw PaymentValidationException('Datos de tarjeta inválidos');
    }

    final tokenResult = await _apiClient.tokenizeCard(
      card: card,
      amount: amount,
      currency: currency,
    );

    if (!tokenResult.success || tokenResult.token == null) {
      return PaymentResult.failed(
        tokenResult.error ?? 'Error al tokenizar tarjeta',
        errorCode: tokenResult.errorCode,
      );
    }

    final paymentResult = await _apiClient.processPayment(
      saleId: saleId,
      method: PaymentMethodType.card,
      cardToken: tokenResult.token,
      cardLastFour: tokenResult.cardLastFour,
      cardBrand: tokenResult.cardBrand,
    );

    return paymentResult;
  }

  Future<PaymentResult> payWithCash({required String saleId}) async {
    return await _apiClient.processPayment(
      saleId: saleId,
      method: PaymentMethodType.cash,
    );
  }

  Future<RefundResult> refundPayment({
    required String transactionId,
    double? amount,
    String? reason,
  }) async {
    return await _apiClient.refundPayment(
      transactionId: transactionId,
      amount: amount,
      reason: reason,
    );
  }

  bool validateCardNumber(String number) =>
      _apiClient.validateCardNumber(number);

  String? detectCardBrand(String number) => _apiClient.detectCardBrand(number);
}

enum PaymentProcessingStatus { idle, processing, success, failed }

class PaymentProcessingState {
  final PaymentProcessingStatus status;
  final PaymentResult? result;
  final String? errorMessage;
  final PaymentMethodType? selectedMethod;

  const PaymentProcessingState({
    this.status = PaymentProcessingStatus.idle,
    this.result,
    this.errorMessage,
    this.selectedMethod,
  });

  PaymentProcessingState copyWith({
    PaymentProcessingStatus? status,
    PaymentResult? result,
    String? errorMessage,
    PaymentMethodType? selectedMethod,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PaymentProcessingState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedMethod: selectedMethod ?? this.selectedMethod,
    );
  }

  bool get isProcessing => status == PaymentProcessingStatus.processing;
  bool get isSuccess => status == PaymentProcessingStatus.success;
  bool get isFailed => status == PaymentProcessingStatus.failed;
  bool get isIdle => status == PaymentProcessingStatus.idle;
}

class PaymentProcessingNotifier extends StateNotifier<PaymentProcessingState> {
  final KushkiPaymentService _paymentService;

  PaymentProcessingNotifier(this._paymentService)
    : super(const PaymentProcessingState());

  void selectPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(
      selectedMethod: method,
      clearError: true,
      clearResult: true,
    );
  }

  Future<PaymentResult?> processCardPayment({
    required String saleId,
    required CardData card,
    required double amount,
    required String currency,
  }) async {
    state = state.copyWith(
      status: PaymentProcessingStatus.processing,
      clearError: true,
    );

    try {
      final result = await _paymentService.payWithCard(
        saleId: saleId,
        card: card,
        amount: amount,
        currency: currency,
      );

      if (result.success) {
        state = state.copyWith(
          status: PaymentProcessingStatus.success,
          result: result,
        );
      } else {
        state = state.copyWith(
          status: PaymentProcessingStatus.failed,
          result: result,
          errorMessage: result.error ?? 'Error al procesar el pago',
        );
      }

      return result;
    } on PaymentException catch (e) {
      state = state.copyWith(
        status: PaymentProcessingStatus.failed,
        errorMessage: e.message,
      );
      return PaymentResult.failed(e.message, errorCode: e.code);
    } catch (e) {
      state = state.copyWith(
        status: PaymentProcessingStatus.failed,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
      );
      return PaymentResult.failed('Error inesperado');
    }
  }

  Future<PaymentResult?> processCashPayment({required String saleId}) async {
    state = state.copyWith(
      status: PaymentProcessingStatus.processing,
      clearError: true,
    );

    try {
      final result = await _paymentService.payWithCash(saleId: saleId);

      if (result.success) {
        state = state.copyWith(
          status: PaymentProcessingStatus.success,
          result: result,
        );
      } else {
        state = state.copyWith(
          status: PaymentProcessingStatus.failed,
          result: result,
          errorMessage: result.error ?? 'Error al procesar el pago',
        );
      }

      return result;
    } on PaymentException catch (e) {
      state = state.copyWith(
        status: PaymentProcessingStatus.failed,
        errorMessage: e.message,
      );
      return PaymentResult.failed(e.message, errorCode: e.code);
    } catch (e) {
      state = state.copyWith(
        status: PaymentProcessingStatus.failed,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
      );
      return PaymentResult.failed('Error inesperado');
    }
  }

  Future<RefundResult?> processRefund({
    required String transactionId,
    double? amount,
    String? reason,
  }) async {
    try {
      return await _paymentService.refundPayment(
        transactionId: transactionId,
        amount: amount,
        reason: reason,
      );
    } on PaymentException catch (e) {
      return RefundResult(success: false, error: e.message);
    }
  }

  void reset() {
    state = const PaymentProcessingState();
  }

  void switchToCash() {
    state = state.copyWith(
      selectedMethod: PaymentMethodType.cash,
      status: PaymentProcessingStatus.idle,
      clearError: true,
      clearResult: true,
    );
  }
}
