import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/config/mock/app_mock.dart';

abstract class OrderRemoteDataSource {
  Future<List<Orden>> getUserOrders();
  Future<Orden> getOrderById(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  Future<T> _simulateApiCall<T>(T Function() callback) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return callback();
  }

  @override
  Future<List<Orden>> getUserOrders() {
    return _simulateApiCall(() => MockData.mockOrders.cast<Orden>());
  }

  @override
  Future<Orden> getOrderById(String orderId) {
    return _simulateApiCall(() {
      final order = MockData.mockOrders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );
      return order;
    });
  }
}

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSourceImpl();
});