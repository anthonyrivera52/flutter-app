import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/orders/presentation/viewmodels/orders_list_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderConfirmationState {
  final bool isLoading;
  final AppOrder? latestOrder;
  final String? errorMessage;

  const OrderConfirmationState({
    this.isLoading = false,
    this.latestOrder,
    this.errorMessage,
  });

  OrderConfirmationState copyWith({
    bool? isLoading,
    AppOrder? latestOrder,
    String? errorMessage,
  }) {
    return OrderConfirmationState(
      isLoading: isLoading ?? this.isLoading,
      latestOrder: latestOrder ?? this.latestOrder,
      errorMessage: errorMessage,
    );
  }
}

final orderConfirmationProvider =
    StateNotifierProvider<OrderConfirmationNotifier, OrderConfirmationState>(
        (ref) => OrderConfirmationNotifier(ref));

class OrderConfirmationNotifier extends StateNotifier<OrderConfirmationState> {
  final Ref _ref;

  OrderConfirmationNotifier(this._ref) : super(const OrderConfirmationState());

  Future<void> fetchLatestUserOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // Reuse the orders list notifier to fetch and grab the first order
    final notifier = _ref.read(ordersListProvider.notifier);
    await notifier.fetchOrders();
    final ordersState = _ref.read(ordersListProvider);
    if (ordersState.errorMessage != null) {
      state = state.copyWith(
          isLoading: false, errorMessage: ordersState.errorMessage);
    } else if (ordersState.orders.isEmpty) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'No se encontraron pedidos.');
    } else {
      state = state.copyWith(
          isLoading: false, latestOrder: ordersState.orders.first);
    }
  }
}
