import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import 'package:mi_tienda/core/network/network_info.dart';
import 'package:mi_tienda/core/network/network_info_impl.dart'; // CORREGIDO: Ruta de importación correcta
import 'package:mi_tienda/core/usecases/usecase.dart'; // Importa NoParams

// Data Sources
import 'package:mi_tienda/data/datasources/auth_remote_datasource.dart';
import 'package:mi_tienda/data/datasources/cart_local_datasource.dart';
import 'package:mi_tienda/data/datasources/product_remote_datasource.dart';
import 'package:mi_tienda/data/datasources/notification_local_datasource.dart'; // Asegúrate de tener esta datasource

// Repositories
import 'package:mi_tienda/data/repositories/auth_repository_impl.dart';
import 'package:mi_tienda/data/repositories/cart_repository_impl.dart';
import 'package:mi_tienda/data/repositories/product_repository_impl.dart';
import 'package:mi_tienda/data/repositories/notification_repository_impl.dart'; // Asegúrate de tener esta implementación
import 'package:mi_tienda/domain/repositories/auth_repository.dart';
import 'package:mi_tienda/domain/repositories/cart_repository.dart';
import 'package:mi_tienda/domain/repositories/product_repository.dart';
import 'package:mi_tienda/domain/repositories/notification_repository.dart'; // Asegúrate de tener este repositorio

// Use Cases Auth
import 'package:mi_tienda/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_in_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_out_usecase.dart';
import 'package:mi_tienda/domain/usecases/auth/sign_up_usecase.dart';

// Use Cases Cart
import 'package:mi_tienda/domain/usecases/cart/add_item_to_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/clear_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/get_cart_items_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/remove_item_from_cart_usecase.dart';
import 'package:mi_tienda/domain/usecases/cart/update_item_quantity_usecase.dart';

// Use Cases Product
import 'package:mi_tienda/domain/usecases/product/get_all_products_usecase.dart';
import 'package:mi_tienda/domain/usecases/product/get_product_by_id_usecase.dart';

// Use Cases Notifications
import 'package:mi_tienda/domain/entities/app_notification.dart'; // Asegúrate de tener esta entidad
import 'package:mi_tienda/domain/usecases/notifications/get_notifications_usecase.dart';
import 'package:mi_tienda/domain/usecases/notifications/add_notification_usecase.dart';


// --- Core Providers ---
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // Este throw es correcto si este provider SIEMPRE será sobrescrito en main.dart
  throw UnimplementedError('SharedPreferences has not been initialized');
});

final connectivityInstanceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  // Este provider ahora solo se define, pero se sobrescribe en main.dart
  // para asegurar que la instancia de Connectivity() sea creada una sola vez
  return NetworkInfoImpl(ref.read(connectivityInstanceProvider));
});

// --- Data Sources Providers ---
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(supabaseClient: ref.read(supabaseClientProvider));
});

final cartLocalDataSourceProvider = Provider<CartLocalDataSource>((ref) {
  return CartLocalDataSourceImpl(sharedPreferences: ref.read(sharedPreferencesProvider));
});

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSourceImpl(supabaseClient: ref.read(supabaseClientProvider));
});

// Notification Data Source (simulada localmente)
final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSourceImpl(sharedPreferences: ref.read(sharedPreferencesProvider));
});


// --- Repositories Providers ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(
    localDataSource: ref.read(cartLocalDataSourceProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.read(productRemoteDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

// Notification Repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(localDataSource: ref.read(notificationLocalDataSourceProvider));
});


// --- Use Cases Providers ---
// Auth Use Cases
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.read(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.read(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.read(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

// Cart Use Cases
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

// Product Use Cases
final getAllProductsUseCaseProvider = Provider<GetAllProductsUseCase>((ref) {
  return GetAllProductsUseCase(ref.read(productRepositoryProvider));
});

final getProductByIdUseCaseProvider = Provider<GetProductByIdUseCase>((ref) {
  return GetProductByIdUseCase(ref.read(productRepositoryProvider));
});

// Notification Use Cases
final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(ref.read(notificationRepositoryProvider));
});

final addNotificationUseCaseProvider = Provider<AddNotificationUseCase>((ref) {
  return AddNotificationUseCase(ref.read(notificationRepositoryProvider));
});


// Función para inicializar y sobrescribir providers en main.dart
// Esta función ahora solo pre-lee providers si es necesario para su inicialización temprana,
// y no intenta modificar la lista de overrides del contenedor.
Future<void> setupRiverpodProviders(ProviderContainer container, SharedPreferences sharedPreferences) async {
  // Ya no se usa container.updateOverrides aquí.
  // Si hay lógica de inicialización temprana que dependa de providers que no son overrides,
  // se puede mantener aquí. Por ejemplo:
  // container.read(someOtherProvider);
}
