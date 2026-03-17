import 'package:flutter_app/features/cart/domain/models/cart_item_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const double kDeliveryFee = 1.20;
const List<double> kTipOptions = [0, 1, 2, 4];

class CheckoutState {
  final bool isSubmitting;
  final String? errorMessage;
  final double selectedTip;
  final String? createdOrderId;
  final String? createdOrderCode;

  const CheckoutState({
    this.isSubmitting = false,
    this.errorMessage,
    this.selectedTip = 2.0,
    this.createdOrderId,
    this.createdOrderCode,
  });

  CheckoutState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    double? selectedTip,
    String? createdOrderId,
    String? createdOrderCode,
    bool clearError = false,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedTip: selectedTip ?? this.selectedTip,
      createdOrderId: createdOrderId ?? this.createdOrderId,
      createdOrderCode: createdOrderCode ?? this.createdOrderCode,
    );
  }

  double subtotal(List<CartItem> items) =>
      items.fold(0.0, (sum, i) => sum + i.subtotal);

  double total(List<CartItem> items) =>
      subtotal(items) + kDeliveryFee + selectedTip;
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final SupabaseClient _supabase;

  CheckoutNotifier(this._supabase) : super(const CheckoutState());

  void selectTip(double tip) =>
      state = state.copyWith(selectedTip: tip, clearError: true);

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

      state = state.copyWith(
        isSubmitting: false,
        createdOrderId: response.data['orderId'] as String?,
        createdOrderCode: response.data['orderCode'] as String?,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'No se pudo crear la orden: $e');
      return false;
    }
  }

  void reset() => state = const CheckoutState();
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(Supabase.instance.client);
});
