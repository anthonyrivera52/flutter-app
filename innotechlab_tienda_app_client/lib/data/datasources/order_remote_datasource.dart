import 'package:flutter_app/data/model/orden_model.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pagination result wrapper
class PaginatedOrders {
  final List<Orden> orders;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedOrders({
    required this.orders,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
  bool get hasPrevious => page > 1;
}

abstract class OrderRemoteDataSource {
  Future<PaginatedOrders> getUserOrders({int page = 1, int limit = 10});
  Future<Orden> getOrderById(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient _supabase;

  OrderRemoteDataSourceImpl(this._supabase);

  @override
  Future<PaginatedOrders> getUserOrders({int page = 1, int limit = 10}) async {
    final response = await _supabase.functions.invoke(
      'get-user-orders',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );

    final rawOrders = (response.data['orders'] as List<dynamic>? ?? const []);
    final pagination = response.data['pagination'] as Map<String, dynamic>?;

    return PaginatedOrders(
      orders: rawOrders
          .map((orderJson) => OrdenModel.fromJson(orderJson as Map<String, dynamic>).toEntity())
          .toList(),
      page: pagination?['page'] as int? ?? page,
      limit: pagination?['limit'] as int? ?? limit,
      total: pagination?['total'] as int? ?? 0,
      totalPages: pagination?['totalPages'] as int? ?? 1,
    );
  }

  @override
  Future<Orden> getOrderById(String orderId) async {
    final response = await _supabase.functions.invoke(
      'track-order',
      body: {'orderId': orderId},
    );

    final raw = response.data['order'] as Map<String, dynamic>?;
    if (raw == null) {
      throw Exception('Order not found');
    }

    return OrdenModel.fromJson(raw).toEntity();
  }
}

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSourceImpl(Supabase.instance.client);
});
