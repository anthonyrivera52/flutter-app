import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/usecases/product/get_all_products_usecase.dart';

class HomeState {
  final bool isLoading;
  final String? errorMessage;
  final List<Product> products;

  HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Product>? products,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      products: products ?? this.products,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final getAllProductsUseCase = ref.watch(getAllProductsUseCaseProvider);
  return HomeNotifier(getAllProductsUseCase);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final GetAllProductsUseCase _getAllProductsUseCase;

  HomeNotifier(this._getAllProductsUseCase) : super(HomeState()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _getAllProductsUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(failure)),
      (products) => state = state.copyWith(isLoading: false, products: products),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) { // <-- Maneja NetworkFailure
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else if (failure is CacheFailure) {
      return failure.message;
    } else {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}