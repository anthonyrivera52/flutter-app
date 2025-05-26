import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Asegúrate de importar Connectivity
import 'package:mi_tienda/domain/usecases/product/get_all_products_usecase.dart';
import 'package:mi_tienda/domain/usecases/product/get_product_by_id_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import 'package:mi_tienda/core/network/network_info.dart';
import 'package:mi_tienda/core/network/network_info_impl.dart';

// Data Sources
import 'package:mi_tienda/data/datasources/auth_remote_datasource.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart';
import 'package:mi_tienda/data/datasources/product_remote_datasource.dart';

// Repositories
import 'package:mi_tienda/data/repositories/auth_repository_impl.dart'; // Si lo tienes aquí
import 'package:mi_tienda/data/repositories/cart_repository_impl.dart';
import 'package:mi_tienda/data/repositories/product_repository_impl.dart';
import 'package:mi_tienda/domain/repositories/auth_repository.dart'; // Si lo tienes aquí
import 'package:mi_tienda/domain/repositories/cart_repository.dart';
import 'package:mi_tienda/domain/repositories/product_repository.dart';

// Use Cases (¡NUEVOS IMPORTS PARA LOS CASOS DE USO DEL CARRITO!)
import 'package:mi_tienda/domain/usecases/cart/add_to_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/remove_from_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/update_item_quantity_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/get_cart_items_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/clear_cart_usecase.dart';

// --- Core Providers ---
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // Asegúrate de que esta instancia se haya inicializado en main.dart y
  // esté disponible para ser usada aquí (ej. usando ProviderScope.overrideWithValue)
  throw UnimplementedError('SharedPreferences not initialized');
});

// Función para configurar SharedPreferences (se llama en main.dart)
// Notar que esto es para una configuración previa antes de que el Provider sea accedido.
Future<void> setupSharedPreferences(ProviderContainer container) async {
  final prefs = await SharedPreferences.getInstance();
  container.updateOverrides([
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final connectivityInstanceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(ref.read(connectivityInstanceProvider));
});

// --- Data Sources Providers ---
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(supabaseClient: ref.read(supabaseClientProvider));
});

final cartLocalDataSourceProvider = Provider<CartLocalDataSource>((ref) {
  return CartLocalDataSourceImpl(sharedPreferences: ref.read(sharedPreferencesProvider));
});

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSourceImpl(supabaseClient: ref.read(supabaseClientProvider));
});

// --- Repositories Providers ---
// Ejemplo: authRepositoryProvider (si lo defines en este archivo de providers)
// final authRepositoryProvider = Provider<AuthRepository>((ref) {
//   return AuthRepositoryImpl(remoteDataSource: ref.read(authRemoteDataSourceProvider));
// });

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(
    localDataSource: ref.read(cartLocalDataSourceProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.read(productRemoteDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider), // Asegúrate de inyectar NetworkInfo
  );
});

// --- Use Cases Providers (¡AQUÍ ES DONDE LOS AGREGAS!) ---

final addItemToCartUseCaseProvider = Provider<AddItemToCartUseCase>((ref) {
  return AddItemToCartUseCase(ref.read(cartRepositoryProvider));
});

final removeItemFromCartUseCaseProvider = Provider<RemoveItemFromCartUseCase>((ref) {
  return RemoveItemFromCartUseCase(ref.read(cartRepositoryProvider));
});

final updateItemQuantityUseCaseProvider = Provider<UpdateItemQuantityUseCase>((ref) {
  return UpdateItemQuantityUseCase(ref.read(cartRepositoryProvider));
});

final getCartItemsUseCaseProvider = Provider<GetCartItemsUseCase>((ref) {
  return GetCartItemsUseCase(ref.read(cartRepositoryProvider));
});

final clearCartUseCaseProvider = Provider<ClearCartUseCase>((ref) {
  return ClearCartUseCase(ref.read(cartRepositoryProvider));
});

// --- Otros Use Cases (ej. productos o autenticación) ---
final getProductByIdUseCaseProvider = Provider<GetProductByIdUseCase>((ref) {
  return GetProductByIdUseCase(ref.read(productRepositoryProvider));
});

final getAllProductsUseCaseProvider = Provider<GetAllProductsUseCase>((ref) {
  return GetAllProductsUseCase(ref.read(productRepositoryProvider));
});