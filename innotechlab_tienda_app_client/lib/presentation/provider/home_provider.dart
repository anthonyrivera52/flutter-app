// Para Either
import 'package:flutter_app/config/mock/app_mock.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/home_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor para el HomeNotifier.
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  // Aquí deberías inyectar tu caso de uso real, por ejemplo:
  // final getAllProductsUseCase = ref.watch(getAllProductsUseCaseProvider);
  // Por ahora, usamos MockData directamente como una simulación.
  final mockProducts = MockData.mockProducts; // Acceso a los productos mockeados
  return HomeNotifier(mockProducts); // Pasa los productos mockeados al notifier
});

class HomeNotifier extends StateNotifier<HomeState> {
  // En un entorno real, esto sería un caso de uso (e.g., GetAllProductsUseCase)
  final List<Product> _mockProducts; // Usamos la lista de productos mockeados directamente

  HomeNotifier(this._mockProducts) : super(const HomeState()) {
    fetchProducts(); // Llama a la carga de productos al inicializar
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Simulación de una llamada asíncrona a la API
      await Future.delayed(const Duration(seconds: 1)); // Simula tiempo de carga

      // Simulación de resultado exitoso
      state = state.copyWith(isLoading: false, products: _mockProducts);

      // Simulación de error (descomenta para probar errores)
      // if (true) { // Por ejemplo, si hay una condición de error
      //   throw NetworkFailure('No se pudo conectar al servidor.');
      // }

    } catch (e) {
      // Mapear el error a un mensaje legible
      state = state.copyWith(isLoading: false, errorMessage: _mapFailureToMessage(e as Failure)); // Asegúrate de castear a Failure si es necesario
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Problemas de conexión a internet. Por favor, revisa tu conexión.';
    } else if (failure is CacheFailure) {
      return failure.message;
    } else if (failure is ProductFailure) {
      return failure.message;
    } else {
      return 'Ocurrió un error inesperado al cargar productos.';
    }
  }
}
