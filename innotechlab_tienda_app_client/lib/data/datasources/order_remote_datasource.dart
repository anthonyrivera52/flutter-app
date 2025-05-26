
// order_remote_datasource.dart (Data Remote Data Source)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/data/models/order_model.dart';
import 'package:mi_tienda/data/models/order_item_model.dart';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/domain/entities/product.dart'; // For product details in order items

abstract class OrderRemoteDataSource {
  Future<void> createOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String shippingAddress,
    required double shippingLatitude,
    required double shippingLongitude,
    String? notes,
  });

  Future<List<OrderModel>> getUserOrders();
  Future<OrderModel> getOrderDetails(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient supabaseClient;

  // Placeholder for store location (replace with actual data or fetch from Supabase)
  static const double _storeLatitude = 6.1363; // Example: Medellín, Colombia
  static const double _storeLongitude = -75.5786; // Example: Medellín, Colombia

  OrderRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> createOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String shippingAddress,
    required double shippingLatitude,
    required double shippingLongitude,
    String? notes,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('Usuario no autenticado.');
      }

      final orderData = {
        'user_id': userId,
        'total_amount': totalAmount,
        'status': 'pending',
        'shipping_address': shippingAddress,
        'shipping_latitude': shippingLatitude,
        'shipping_longitude': shippingLongitude,
        'store_latitude': _storeLatitude, // Fixed store location
        'store_longitude': _storeLongitude, // Fixed store location
        'notes': notes,
      };

      final response = await supabaseClient.from('orders').insert(orderData).select().single();
      if (response == null) {
        throw ServerException('Failed to create order.');
      }

      final orderId = response['id'] as String;

      final orderItemsData = cartItems.map((item) {
        return {
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price, // Store price at time of order
        };
      }).toList();

      await supabaseClient.from('order_items').insert(orderItemsData);
    } catch (e) {
      throw ServerException('Failed to place order: $e');
    }
  }

  @override
  Future<List<OrderModel>> getUserOrders() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('Usuario no autenticado.');
      }

      final response = await supabaseClient
          .from('orders')
          .select('*, order_items(*, products(*))') // Fetch order items and product details
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response == null) {
        throw ServerException('No orders found or network error.');
      }

      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch user orders: $e');
    }
  }

  @override
  Future<OrderModel> getOrderDetails(String orderId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('id', orderId)
          .single();

      if (response == null) {
        throw NotFoundException('Order not found with ID: $orderId');
      }
      return OrderModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch order details: $e');
    }
  }
}

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSourceImpl(supabaseClient: Supabase.instance.client);
});
