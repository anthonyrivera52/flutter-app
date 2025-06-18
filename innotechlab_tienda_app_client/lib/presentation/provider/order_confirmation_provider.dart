
// order_confirmation_provider.dart (ViewModel)
import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_app/domain/usecase/order_confirmation/get_user_orders_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderConfirmationState {
  final bool isLoading;
  final Orden? latestOrder;
  final String? errorMessage;

  OrderConfirmationState({this.isLoading = false, this.latestOrder, this.errorMessage});

  OrderConfirmationState copyWith({
    bool? isLoading,
    Orden? latestOrder,
    String? errorMessage,
  }) {
    return OrderConfirmationState(
      isLoading: isLoading ?? this.isLoading,
      latestOrder: latestOrder ?? this.latestOrder,
      errorMessage: errorMessage,
    );
  }
}

final orderConfirmationProvider = StateNotifierProvider<OrderConfirmationNotifier, OrderConfirmationState>((ref) {
  return OrderConfirmationNotifier(
    getUserOrdersUseCase: ref.read(getUserOrdersUseCaseProvider),
  );
});

class OrderConfirmationNotifier extends StateNotifier<OrderConfirmationState> {
  final GetUserOrdersUseCase getUserOrdersUseCase;

  OrderConfirmationNotifier({required this.getUserOrdersUseCase}) : super(OrderConfirmationState());

  Future<void> fetchLatestUserOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await getUserOrdersUseCase(NoParams());
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (orders) {
        if (orders.isNotEmpty) {
          // Assume the first one is the latest or sort by created_at if necessary
          // final latest = orders.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
          final latest = orders.first as Orden?;
          state = state.copyWith(isLoading: false, latestOrder: latest);
        } else {
          state = state.copyWith(isLoading: false, latestOrder: null, errorMessage: 'No se encontraron pedidos.');
        }
      },
    );
  }
}
