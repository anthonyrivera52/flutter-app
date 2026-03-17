import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/orders/domain/usecases/get_user_orders_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdersListState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<AppOrder> orders;
  final String? errorMessage;
  final String? nextCursor;
  final bool hasMore;

  const OrdersListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.orders = const [],
    this.errorMessage,
    this.nextCursor,
    this.hasMore = true,
  });

  OrdersListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<AppOrder>? orders,
    String? errorMessage,
    String? nextCursor,
    bool? hasMore,
    bool clearError = false,
  }) {
    return OrdersListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      orders: orders ?? this.orders,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class OrdersListNotifier extends StateNotifier<OrdersListState> {
  final GetUserOrdersUseCase _useCase;
  OrdersListNotifier(this._useCase) : super(const OrdersListState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _useCase(const GetUserOrdersParams());
    result.fold(
      (f) => state = state.copyWith(isLoading: false, errorMessage: f.message),
      (p) => state = state.copyWith(
        isLoading: false,
        orders: p.orders,
        nextCursor: p.nextCursor,
        hasMore: p.hasMore,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final result = await _useCase(GetUserOrdersParams(cursor: state.nextCursor));
    result.fold(
      (f) => state = state.copyWith(
          isLoadingMore: false, errorMessage: f.message),
      (p) => state = state.copyWith(
        isLoadingMore: false,
        orders: [...state.orders, ...p.orders],
        nextCursor: p.nextCursor,
        hasMore: p.hasMore,
      ),
    );
  }

  Future<void> refresh() => fetchOrders();
}

final ordersListProvider =
    StateNotifierProvider<OrdersListNotifier, OrdersListState>((ref) {
  return OrdersListNotifier(ref.watch(getUserOrdersUseCaseProvider));
});
