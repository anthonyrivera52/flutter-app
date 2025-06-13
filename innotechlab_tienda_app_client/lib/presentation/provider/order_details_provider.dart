import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_app/domain/usecase/order/get_order_by_id_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderDetailsState {
  final bool isLoading;
  final Orden? order;
  final String? errorMessage;

  OrderDetailsState({
    this.isLoading = false,
    this.order,
    this.errorMessage,
  });

  OrderDetailsState copyWith({
    bool? isLoading,
    Orden? order,
    String? errorMessage,
    bool clearOrder = false,
    bool clearErrorMessage = false,
  }) {
    return OrderDetailsState(
      isLoading: isLoading ?? this.isLoading,
      order: clearOrder ? null : order ?? this.order,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class OrderDetailsNotifier extends StateNotifier<OrderDetailsState> {
  final GetOrderByIdUseCase _getOrderByIdUseCase;

  OrderDetailsNotifier(this._getOrderByIdUseCase) : super(OrderDetailsState());

  Future<void> fetchOrderDetails(String orderId) async {
    state = state.copyWith(isLoading: true, clearOrder: true, clearErrorMessage: true);

    final params = GetOrderByIdParams(orderId: orderId);
    final result = await _getOrderByIdUseCase.call(params);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (order) {
        state = state.copyWith(isLoading: false, order: order as Orden);
      },
    );
  }
}

final orderDetailsProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailsNotifier, OrderDetailsState, String>((ref, orderId) {
  final getOrderByIdUseCase = ref.watch(getOrderByIdUseCaseProvider);
  final notifier = OrderDetailsNotifier(getOrderByIdUseCase);
  return notifier;
});