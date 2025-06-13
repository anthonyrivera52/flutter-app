import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/provider/order_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class OrdersListPage extends ConsumerWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersListProvider);

    if (ordersState.orders.isEmpty && !ordersState.isLoading && ordersState.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ordersListProvider.notifier).fetchOrders();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
      ),
      body: _buildBody(context, ordersState, ref),
    );
  }

  Widget _buildBody(BuildContext context, OrdersListState ordersState, WidgetRef ref) {
    if (ordersState.isLoading && ordersState.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ordersState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${ordersState.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(ordersListProvider.notifier).fetchOrders(),
              child: const Text('Reintentar'),
            )
          ],
        ),
      );
    }

    if (ordersState.orders.isEmpty) {
      return const Center(child: Text('No tienes pedidos aún.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersListProvider.notifier).fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: ordersState.orders.length,
        itemBuilder: (context, index) {
          final order = ordersState.orders[index];
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal());
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(
                'Pedido #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Fecha: $formattedDate'),
                  const SizedBox(height: 2),
                  Text('Estado: ${order.status}', style: TextStyle(color: _getStatusColor(order.status))),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              onTap: () {
                context.go('/order-details/${order.id}');
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}