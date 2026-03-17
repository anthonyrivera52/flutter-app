import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/orders/domain/usecases/get_order_by_id_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderDetailsState {
  final bool isLoading;
  final AppOrder? order;
  final String? errorMessage;

  const OrderDetailsState({
    this.isLoading = false,
    this.order,
    this.errorMessage,
  });

  OrderDetailsState copyWith({
    bool? isLoading,
    AppOrder? order,
    String? errorMessage,
    bool clearError = false,
    bool clearOrder = false,
  }) {
    return OrderDetailsState(
      isLoading: isLoading ?? this.isLoading,
      order: clearOrder ? null : order ?? this.order,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class OrderDetailsNotifier extends StateNotifier<OrderDetailsState> {
  final GetOrderByIdUseCase _useCase;
  OrderDetailsNotifier(this._useCase) : super(const OrderDetailsState());

  Future<void> fetchOrderDetails(String orderId) async {
    state = state.copyWith(isLoading: true, clearOrder: true, clearError: true);
    final result = await _useCase(GetOrderByIdParams(orderId: orderId));
    result.fold(
      (f) => state = state.copyWith(isLoading: false, errorMessage: f.message),
      (o) => state = state.copyWith(isLoading: false, order: o),
    );
  }
}

final orderDetailsProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailsNotifier, OrderDetailsState, String>((ref, orderId) {
  final notifier = OrderDetailsNotifier(ref.watch(getOrderByIdUseCaseProvider));
  notifier.fetchOrderDetails(orderId);
  return notifier;
});
