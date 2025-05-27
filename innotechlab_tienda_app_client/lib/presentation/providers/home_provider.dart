import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/product.dart';
import 'package:mi_tienda/domain/usecases/product/get_all_products_usecase.dart';
import 'package:mi_tienda/domain/usecases/product/get_product_by_id_usecase.dart';
import 'package:mi_tienda/service_locator.dart';

// Estado de la página de inicio
class HomeState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  HomeState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Proveedor de la página de inicio
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final getAllProductsUseCase = ref.watch(getAllProductsUseCaseProvider);
  return HomeNotifier(getAllProductsUseCase);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final GetAllProductsUseCase _getAllProductsUseCase;

  HomeNotifier(this._getAllProductsUseCase) : super(HomeState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
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
    } else if (failure is NetworkFailure) {
      return 'No hay conexión a internet. Por favor, revisa tu conexión.';
    } else {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}

// Proveedor específico para los detalles de un producto por ID
final productDetailsProvider = FutureProvider.family<Product?, String>((ref, productId) async {
  final getProductByIdUseCase = ref.watch(getProductByIdUseCaseProvider);
  final result = await getProductByIdUseCase(GetProductByIdParams(id: productId));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (product) => product,
  );
});
