import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/presentation/pages/order_confirmation/order_confirmation_page.dart'; // For NoParams

// Part 1: State Definition
class OrdersListState {
  final bool isLoading;
  final List<Order> orders;
  final String? errorMessage;

  OrdersListState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
  });

  OrdersListState copyWith({
    bool? isLoading,
    List<Order>? orders,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return OrdersListState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Part 2: Notifier Definition
class OrdersListNotifier extends StateNotifier<OrdersListState> {
  final GetUserOrdersUseCase _getUserOrdersUseCase;

  OrdersListNotifier(this._getUserOrdersUseCase) : super(OrdersListState()) {
    // Optionally, fetch orders immediately when the provider is initialized
    // fetchOrders(); 
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    final result = await _getUserOrdersUseCase.call(const NoParams());
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (orders) {
        state = state.copyWith(isLoading: false, orders: orders.cast<Order>());
      },
    );
  }
}

// Part 3: Provider Definition
final ordersListProvider = StateNotifierProvider<OrdersListNotifier, OrdersListState>((ref) {
  // Assuming getUserOrdersUseCaseProvider is already defined and provides GetUserOrdersUseCase
  // This is how it's done in OrderConfirmationProvider for example.
  final getUserOrdersUseCase = ref.watch(getUserOrdersUseCaseProvider);
  return OrdersListNotifier(getUserOrdersUseCase);
});
