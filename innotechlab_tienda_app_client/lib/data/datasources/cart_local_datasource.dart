import 'dart:convert';
import 'package:mi_tienda/presentation/pages/cart/cart_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';

abstract class CartLocalDataSource {
  Future<List<CartItemModel>> getCartItems();
  Future<List<CartItemModel>> saveCartItems(List<CartItemModel> items);
  Future<void> clearCart();

  // Opcional: Para controlar si el onboarding ya se mostró
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool isCompleted);
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _CART_KEY = 'cart_items';
  static const String _ONBOARDING_KEY = 'onboarding_completed';

  CartLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CartItemModel>> getCartItems() {
    try {
      final String? jsonString = sharedPreferences.getString(_CART_KEY);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return Future.value(jsonList.map((json) => CartItemModel.fromJson(json)).toList());
      }
      return Future.value([]); // Retorna una lista vacía si no hay ítems
    } catch (e) {
      throw CacheException('Error al obtener ítems del carrito: $e');
    }
  }

  @override
  Future<List<CartItemModel>> saveCartItems(List<CartItemModel> items) {
    try {
      final List<Map<String, dynamic>> jsonList = items.map((item) => item.toJson()).toList();
      final String jsonString = json.encode(jsonList);
      sharedPreferences.setString(_CART_KEY, jsonString);
      return Future.value(items);
    } catch (e) {
      throw CacheException('Error al guardar ítems del carrito: $e');
    }
  }

  @override
  Future<void> clearCart() {
    try {
      sharedPreferences.remove(_CART_KEY);
      return Future.value();
    } catch (e) {
      throw CacheException('Error al limpiar el carrito: $e');
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    try {
      return sharedPreferences.getBool(_ONBOARDING_KEY) ?? false;
    } catch (e) {
      throw CacheException('Error al verificar estado de onboarding: $e');
    }
  }

  @override
  Future<void> setOnboardingCompleted(bool isCompleted) async {
    try {
      await sharedPreferences.setBool(_ONBOARDING_KEY, isCompleted);
    } catch (e) {
      throw CacheException('Error al guardar estado de onboarding: $e');
    }
  }
}