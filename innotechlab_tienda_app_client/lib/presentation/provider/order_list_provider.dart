import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_app/domain/usecase/order/get_user_orders_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdersListState {
  final bool isLoading;
  final List<Orden> orders;
  final String? errorMessage;

  OrdersListState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
  });

  OrdersListState copyWith({
    bool? isLoading,
    List<Orden>? orders,
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

class OrdersListNotifier extends StateNotifier<OrdersListState> {
  final GetUserOrdersUseCase _getUserOrdersUseCase;

  OrdersListNotifier(this._getUserOrdersUseCase) : super(OrdersListState()) {
    // Puedes descomentar para cargar órdenes al inicializar el proveedor
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
        state = state.copyWith(isLoading: false, orders: orders.cast<Orden>());
      },
    );
  }
}

final ordersListProvider = StateNotifierProvider<OrdersListNotifier, OrdersListState>((ref) {
  final getUserOrdersUseCase = ref.watch(getUserOrdersUseCaseProvider);
  return OrdersListNotifier(getUserOrdersUseCase);
});