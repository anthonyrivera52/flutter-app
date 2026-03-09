import 'package:flutter_app/data/datasources/order_remote_datasource.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para paginación de pedidos
class OrdersListState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<Orden> orders;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;

  const OrdersListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.orders = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = true,
  });

  OrdersListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<Orden>? orders,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    bool clearErrorMessage = false,
  }) {
    return OrdersListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      orders: orders ?? this.orders,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class OrdersListNotifier extends StateNotifier<OrdersListState> {
  final OrderRemoteDataSource _dataSource;

  OrdersListNotifier(this._dataSource) : super(const OrdersListState());

  /// Cargar la primera página de pedidos
  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final result = await _dataSource.getUserOrders(page: 1, limit: 10);
      state = state.copyWith(
        isLoading: false,
        orders: result.orders,
        currentPage: 1,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar pedidos: $e',
      );
    }
  }

  /// Cargar más pedidos (paginación infinita)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _dataSource.getUserOrders(page: nextPage, limit: 10);
      state = state.copyWith(
        isLoadingMore: false,
        orders: [...state.orders, ...result.orders],
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Error al cargar más pedidos: $e',
      );
    }
  }

  /// Refrescar pedidos
  Future<void> refresh() async {
    await fetchOrders();
  }
}

/// Provider principal para lista de pedidos
final ordersListProvider = StateNotifierProvider<OrdersListNotifier, OrdersListState>((ref) {
  final dataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrdersListNotifier(dataSource);
});
