import 'package:delivery_app_mvvm/model/order.dart';

// Define la interfaz para el servicio de órdenes
abstract class OrderService {
  Future<Order?> fetchNewOrder();
  Future<void> updateOrderStatus(String orderId, String newStatus);
  // Podrías añadir más métodos como fetchActiveOrders, etc.
}