import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutState {
  final bool isLoading;
  final String? errorMessage;
  final List<CartItem> cartItems;

  CheckoutState({
    this.isLoading = false,
    this.errorMessage,
    this.cartItems = const [],
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CartItem>? cartItems,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      cartItems: cartItems ?? this.cartItems,
    );
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  // final clearCartUseCase = ref.watch(clearCartUseCaseProvider);
  final supabaseClient = Supabase.instance.client; // Obtener la instancia de Supabase
  return CheckoutNotifier(supabaseClient, ref);
});

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  // final ClearCartUseCase _clearCartUseCase;
  final SupabaseClient _supabaseClient; // Inyectar SupabaseClient
  final Ref _ref; // Inyectar Ref para acceder a otros providers

  CheckoutNotifier(this._supabaseClient, this._ref) : super(CheckoutState());

  void loadCartItems(List<CartItem> items) {
    state = state.copyWith(cartItems: items);
  }

  Future<bool> processPayment(String cardNumber, String expiryDate, String cvv) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Simular un procesamiento de pago exitoso
      await Future.delayed(const Duration(seconds: 2));

      // Aquí podrías integrar un gateway de pago real
      if (cardNumber.isEmpty || expiryDate.isEmpty || cvv.isEmpty) {
        throw Exception('Datos de pago inválidos.');
      }

      final success = await confirmOrder(); // Confirmar la orden después del pago
      if (success) {
        return true;
      } else {
        throw Exception(state.errorMessage ?? 'Error al confirmar la orden.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> confirmOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Usuario no autenticado.');
        return false;
      }

      // 1. Crear la orden en la base de datos con estado 'pending'
      final orderResponse = await _supabaseClient.from('orders').insert({
        'user_id': userId,
        'total_amount': state.cartItems.fold(0.0, (sum, item) => sum + item.price * item.quantity),
        'status': 'pending', // Estado inicial
        // Puedes añadir otros campos de la orden aquí (ej. shipping_address)
      }).select().single(); // Obtener la orden recién creada

      final orderId = orderResponse['id'];

      // 2. Crear los ítems de la orden
      final orderItems = state.cartItems.map((item) => {
            'order_id': orderId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'price_at_purchase': item.price,
          }).toList();

      await _supabaseClient.from('order_items').insert(orderItems);

      // 3. ACTUALIZAR EL ESTADO A 'confirmed' - ESTO DISPARARÁ EL TRIGGER DE SUPABASE
      await _supabaseClient.from('orders').update({
        'status': 'confirmed',
      }).eq('id', orderId);

      // 4. Limpiar el carrito local
      state.cartItems.clear();

      state = state.copyWith(isLoading: false, cartItems: []);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al confirmar la orden: ${e.toString()}');
      return false;
    }
  }
}