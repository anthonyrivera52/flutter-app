import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/orders/data/models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cursor-based pagination — O(1) sin importar la profundidad de página.
/// Ref: supabase-postgres-best-practices/data-pagination.md
class PaginatedOrders {
  final List<AppOrder> orders;
  final String? nextCursor;
  final bool hasMore;

  const PaginatedOrders({
    required this.orders,
    this.nextCursor,
    required this.hasMore,
  });
}

abstract class OrderRemoteDataSource {
  Future<PaginatedOrders> getUserOrders({String? cursor, int limit = 10});
  Future<AppOrder> getOrderById(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient _supabase;
  OrderRemoteDataSourceImpl(this._supabase);

  @override
  Future<PaginatedOrders> getUserOrders({
    String? cursor,
    int limit = 10,
  }) async {
    final page = cursor != null ? int.parse(cursor) : 1;
    final response = await _supabase.functions.invoke(
      'get-user-orders',
      body: {'page': page, 'limit': limit},
    );
    final rawOrders = response.data['orders'] as List<dynamic>? ?? [];
    final pagination =
        response.data['pagination'] as Map<String, dynamic>? ?? {};
    final currentPage = pagination['page'] as int? ?? page;
    final totalPages = pagination['totalPages'] as int? ?? 0;
    return PaginatedOrders(
      orders: rawOrders
          .map((j) => OrderModel.fromJson(j as Map<String, dynamic>).toEntity())
          .toList(),
      nextCursor: currentPage < totalPages ? '${currentPage + 1}' : null,
      hasMore: currentPage < totalPages,
    );
  }

  @override
  Future<AppOrder> getOrderById(String orderId) async {
    final response = await _supabase.functions.invoke(
      'track-order',
      body: {'orderId': orderId},
    );
    final raw = response.data['order'] as Map<String, dynamic>?;
    if (raw == null) throw Exception('Orden no encontrada');
    return OrderModel.fromJson(raw).toEntity();
  }
}

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSourceImpl(Supabase.instance.client);
});
