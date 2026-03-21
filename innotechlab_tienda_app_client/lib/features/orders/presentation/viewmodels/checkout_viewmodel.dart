import 'package:flutter_app/features/cart/domain/models/cart_item_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/payments/payment_models.dart';
import '../../../../core/services/payments/kushki_payment_service.dart';

const double kDeliveryFee = 1.20;
const List<double> kTipOptions = [0, 1, 2, 4];

class CheckoutState {
  final bool isSubmitting;
  final String? errorMessage;
  final double selectedTip;
  final String? createdOrderId;
  final String? createdOrderCode;
  final PaymentMethodType selectedPaymentMethod;
  final PaymentProcessingStatus paymentStatus;
  final String? paymentError;

  const CheckoutState({
    this.isSubmitting = false,
    this.errorMessage,
    this.selectedTip = 2.0,
    this.createdOrderId,
    this.createdOrderCode,
    this.selectedPaymentMethod = PaymentMethodType.cash,
    this.paymentStatus = PaymentProcessingStatus.idle,
    this.paymentError,
  });

  CheckoutState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    double? selectedTip,
    String? createdOrderId,
    String? createdOrderCode,
    bool clearError = false,
    PaymentMethodType? selectedPaymentMethod,
    PaymentProcessingStatus? paymentStatus,
    String? paymentError,
    bool clearPaymentError = false,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedTip: selectedTip ?? this.selectedTip,
      createdOrderId: createdOrderId ?? this.createdOrderId,
      createdOrderCode: createdOrderCode ?? this.createdOrderCode,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentError: clearPaymentError
          ? null
          : paymentError ?? this.paymentError,
    );
  }

  double subtotal(List<CartItem> items) =>
      items.fold(0.0, (sum, i) => sum + i.subtotal);

  double total(List<CartItem> items) =>
      subtotal(items) + kDeliveryFee + selectedTip;

  bool get isPaymentProcessing =>
      paymentStatus == PaymentProcessingStatus.processing;
  bool get isPaymentSuccess => paymentStatus == PaymentProcessingStatus.success;
  bool get isPaymentFailed => paymentStatus == PaymentProcessingStatus.failed;
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final SupabaseClient _supabase;
  final KushkiPaymentService _paymentService;

  CheckoutNotifier(this._supabase, this._paymentService)
    : super(const CheckoutState());

  void selectTip(double tip) =>
      state = state.copyWith(selectedTip: tip, clearError: true);

  void selectPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(
      selectedPaymentMethod: method,
      clearPaymentError: true,
    );
  }

  Future<bool> placeOrder({
    required String shopId,
    required List<CartItem> cartItems,
    required String shippingAddress,
    String? notes,
    double? shippingLatitude,
    double? shippingLongitude,
  }) async {
    if (cartItems.isEmpty) {
      state = state.copyWith(errorMessage: 'Tu carrito está vacío.');
      return false;
    }
    if (shippingAddress.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Ingresa una dirección de entrega.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final response = await _supabase.functions.invoke(
        'create-order',
        body: {
          'shopId': shopId,
          'shippingAddress': shippingAddress,
          'shippingLatitude': shippingLatitude ?? 0,
          'shippingLongitude': shippingLongitude ?? 0,
          'notes': notes,
          'tipAmount': state.selectedTip,
          'items': cartItems
              .map((i) => {'productId': i.productId, 'quantity': i.quantity})
              .toList(),
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['orderId'] == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Error al crear la orden',
        );
        return false;
      }

      state = state.copyWith(
        isSubmitting: false,
        createdOrderId: data['orderId'] as String?,
        createdOrderCode: data['orderCode'] as String?,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'No se pudo crear la orden: $e',
      );
      return false;
    }
  }

  Future<bool> processPayment({
    required String saleId,
    required CardData? cardData,
    required double amount,
    String currency = 'USD',
  }) async {
    state = state.copyWith(
      paymentStatus: PaymentProcessingStatus.processing,
      clearPaymentError: true,
    );

    try {
      PaymentResult result;

      if (state.selectedPaymentMethod == PaymentMethodType.card &&
          cardData != null) {
        result = await _paymentService.payWithCard(
          saleId: saleId,
          card: cardData,
          amount: amount,
          currency: currency,
        );
      } else {
        result = await _paymentService.payWithCash(saleId: saleId);
      }

      if (result.success) {
        state = state.copyWith(paymentStatus: PaymentProcessingStatus.success);
        return true;
      } else {
        state = state.copyWith(
          paymentStatus: PaymentProcessingStatus.failed,
          paymentError: result.error ?? 'Error al procesar el pago',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        paymentStatus: PaymentProcessingStatus.failed,
        paymentError: 'Error de conexión. Intenta de nuevo.',
      );
      return false;
    }
  }

  void switchToCash() {
    state = state.copyWith(
      selectedPaymentMethod: PaymentMethodType.cash,
      paymentStatus: PaymentProcessingStatus.idle,
      clearPaymentError: true,
    );
  }

  void reset() => state = const CheckoutState();
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    return CheckoutNotifier(
      Supabase.instance.client,
      ref.watch(kushkiPaymentServiceProvider),
    );
  },
);
