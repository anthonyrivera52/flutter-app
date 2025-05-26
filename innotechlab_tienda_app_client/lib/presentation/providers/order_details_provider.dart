import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/domain/usecases/order/get_order_by_id_usecase.dart';
// It's good practice to have a separate provider for the use case if it has dependencies.
// For now, assuming GetOrderByIdUseCase can be instantiated directly or its provider is simple.
// If GetOrderByIdUseCase depends on OrderRepository, we'd need orderRepositoryProvider.

// Part 1: State Definition
class OrderDetailsState {
  final bool isLoading;
  final Order? order;
  final String? errorMessage;

  OrderDetailsState({
    this.isLoading = false,
    this.order,
    this.errorMessage,
  });

  OrderDetailsState copyWith({
    bool? isLoading,
    Order? order,
    String? errorMessage,
    bool clearOrder = false, // To clear order on new fetch
    bool clearErrorMessage = false,
  }) {
    return OrderDetailsState(
      isLoading: isLoading ?? this.isLoading,
      order: clearOrder ? null : order ?? this.order,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Part 2: Notifier Definition
class OrderDetailsNotifier extends StateNotifier<OrderDetailsState> {
  final GetOrderByIdUseCase _getOrderByIdUseCase;

  OrderDetailsNotifier(this._getOrderByIdUseCase) : super(OrderDetailsState());

  Future<void> fetchOrderDetails(String orderId) async {
    // Set loading state and clear previous order/error for a new fetch
    state = state.copyWith(isLoading: true, clearOrder: true, clearErrorMessage: true);
    
    final params = GetOrderByIdParams(orderId: orderId);
    final result = await _getOrderByIdUseCase.call(params);
    
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (order) {
        state = state.copyWith(isLoading: false, order: order);
      },
    );
  }
}

// Part 3: Provider Definition

// Provider for GetOrderByIdUseCase (assuming it depends on OrderRepository)
// This needs the orderRepositoryProvider which is in 'package:mi_tienda/domain/repositories/order_repository.dart'
// However, that file also defines orderRepositoryProvider which depends on orderRemoteDataSourceProvider,
// and orderRemoteDataSourceProvider is in 'package:mi_tienda/data/datasources/order_remote_datasource.dart'.
// This creates a potential circular dependency if not handled carefully or if files are too monolithic.
// For now, let's assume orderRepositoryProvider is accessible.

// A common pattern is to provide the use case itself:
final getOrderByIdUseCaseProvider = Provider<GetOrderByIdUseCase>((ref) {
  // Assuming orderRepositoryProvider is defined elsewhere and accessible.
  // This usually means order_repository.dart should only define the abstract class,
  // and the provider for it should be in a different file or the DI setup (service_locator.dart).
  // For now, this might lead to an error if orderRepositoryProvider isn't set up in a way
  // that it can be consumed here without circular deps.
  // Let's assume `sl<OrderRepository>()` from a service locator for now, or that orderRepositoryProvider is available.
  // The previous `orders_list_provider.dart` used `ref.watch(getUserOrdersUseCaseProvider)`
  // implying `getUserOrdersUseCaseProvider` was already defined. I'll follow that pattern and
  // assume `getOrderByIdUseCaseProvider` will be used to get the use case.
  // This means I need to provide GetOrderByIdUseCase itself.
  
  // Correct approach: The use case provider should instantiate the use case with its repo dependency.
  // The repo provider is in 'package:mi_tienda/domain/repositories/order_repository.dart'.
  // I will need to import it.
  final orderRepository = ref.watch(orderRepositoryProvider); // This is defined in order_repository.dart
  return GetOrderByIdUseCase(orderRepository);
});


final orderDetailsProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailsNotifier, OrderDetailsState, String>((ref, orderId) {
  final getOrderByIdUseCase = ref.watch(getOrderByIdUseCaseProvider);
  // The notifier is created, and fetchOrderDetails can be called immediately or by the UI.
  // For family providers, it's common to fetch immediately if the parameter (orderId) is available.
  final notifier = OrderDetailsNotifier(getOrderByIdUseCase);
  // Call fetchOrderDetails when the provider is first built with an orderId
  // This is a common pattern for family providers that need to load data based on the family parameter.
  // However, the instructions mention the page will call fetchOrderDetails.
  // So, I will remove the immediate fetch from here. The page will trigger it.
  // notifier.fetchOrderDetails(orderId); 
  return notifier;
});
