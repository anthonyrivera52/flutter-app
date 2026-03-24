import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/orders/domain/models/order_entity.dart'
    show AppOrder;
import 'package:flutter_app/features/orders/presentation/viewmodels/order_details_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends ConsumerWidget {
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Estado del pedido')),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    OrderDetailsState state,
  ) {
    if (state.isLoading && state.order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref
                    .read(orderDetailsProvider(orderId).notifier)
                    .fetchOrderDetails(orderId),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final order = state.order;
    if (order == null) {
      return const Center(child: Text('No se encontró el pedido.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(orderDetailsProvider(orderId).notifier)
          .fetchOrderDetails(orderId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderHeader(order: order),
          const SizedBox(height: 16),
          _StatusTimeline(status: order.status),
          const SizedBox(height: 16),
          if (order.driverId != null) ...[
            _DriverCard(order: order),
            const SizedBox(height: 16),
          ],
          _PaymentBreakdown(order: order),
          const SizedBox(height: 16),
          _OrderMap(order: order),
          const SizedBox(height: 18),
          _ItemsList(order: order),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final AppOrder order;
  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(order.createdAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedido #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(formattedDate),
        Text(
          'Total: \$${order.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text('Entrega: ${order.shippingAddress}'),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  final AppOrder order;
  const _DriverCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: order.driverPhotoUrl != null
              ? NetworkImage(order.driverPhotoUrl!)
              : null,
          child: order.driverPhotoUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(
          order.driverName ?? 'Domiciliario',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.driverPhone != null) Text('📱 ${order.driverPhone}'),
            if (order.vehicleType != null)
              Text(
                '🚗 ${order.vehicleType}${order.vehiclePlate != null ? ' (${order.vehiclePlate})' : ''}',
              ),
          ],
        ),
        trailing: const Icon(Icons.chat),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  final AppOrder order;
  const _PaymentBreakdown({required this.order});

  @override
  Widget build(BuildContext context) {
    final subtotal = order.subtotalAmount ?? order.totalAmount;
    final shipping = order.shippingAmount ?? 0.0;
    final tax = order.taxIvaAmount ?? 0.0;
    final tip = order.tipAmount ?? 0.0;
    final paymentInfo = order.paymentInfo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumen de Pago',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (paymentInfo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(
                        paymentInfo.paymentStatus,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          paymentInfo.isOnline
                              ? Icons.credit_card
                              : Icons.payments,
                          size: 14,
                          color: _getPaymentStatusColor(
                            paymentInfo.paymentStatus,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          paymentInfo.paymentMethodText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getPaymentStatusColor(
                              paymentInfo.paymentStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (paymentInfo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    paymentInfo.isPaid ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: _getPaymentStatusColor(paymentInfo.paymentStatus),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getPaymentStatusText(paymentInfo.paymentStatus),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPaymentStatusColor(paymentInfo.paymentStatus),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _row('Subtotal', subtotal),
            _row('Envío', shipping),
            _row('Impuestos', tax),
            if (tip > 0) _row('Propina', tip),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (paymentInfo?.transactionId != null) ...[
              const SizedBox(height: 8),
              Text(
                'ID Transacción: ${paymentInfo!.transactionId}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text('\$${amount.toStringAsFixed(2)}')],
    ),
  );

  Color _getPaymentStatusColor(dynamic paymentStatus) {
    switch (paymentStatus?.toString()) {
      case 'OrderPaymentStatus.paid':
        return Colors.green;
      case 'OrderPaymentStatus.pending':
      case 'OrderPaymentStatus.processing':
        return Colors.orange;
      case 'OrderPaymentStatus.failed':
        return Colors.red;
      case 'OrderPaymentStatus.refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(dynamic paymentStatus) {
    switch (paymentStatus?.toString()) {
      case 'OrderPaymentStatus.paid':
        return 'Pagado';
      case 'OrderPaymentStatus.pending':
        return 'Pendiente';
      case 'OrderPaymentStatus.processing':
        return 'Procesando';
      case 'OrderPaymentStatus.failed':
        return 'Fallido';
      case 'OrderPaymentStatus.refunded':
        return 'Reembolsado';
      case 'OrderPaymentStatus.partiallyRefunded':
        return 'Parcialmente reembolsado';
      default:
        return 'Estado desconocido';
    }
  }
}

class _OrderMap extends ConsumerWidget {
  final AppOrder order;
  const _OrderMap({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLocation = LatLng(
      order.shippingLatitude,
      order.shippingLongitude,
    );
    final storeLocation = LatLng(order.storeLatitude, order.storeLongitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          markers: {
            Marker(
              markerId: const MarkerId('userLocation'),
              position: userLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
            Marker(
              markerId: const MarkerId('storeLocation'),
              position: storeLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              (userLocation.latitude + storeLocation.latitude) / 2,
              (userLocation.longitude + storeLocation.longitude) / 2,
            ),
            zoom: 15,
          ),
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final AppOrder order;
  const _ItemsList({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...order.items.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.product.imageUrl.isNotEmpty
                    ? Image.network(
                        item.product.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
              title: Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${item.quantity} x \$${item.priceAtPurchase.toStringAsFixed(2)}',
              ),
              trailing: Text(
                '\$${(item.quantity * item.priceAtPurchase).toStringAsFixed(2)}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() => Container(
    width: 52,
    height: 52,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported_outlined),
  );
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    ('Pendiente', 'Esperando confirmación'),
    ('Aceptado', 'Pedido confirmado por la tienda'),
    ('Preparando', 'Estamos preparando tu pedido'),
    ('En camino', 'El pedido va en ruta'),
    ('Entregado', 'Pedido completado'),
  ];

  static const _indexByStatus = {
    'new': 0,
    'pending': 0,
    'preparing': 1,
    'ready_for_pickup': 2,
    'out_for_delivery': 3,
    'delivered': 4,
    'completed': 4,
  };

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    if (normalized == 'cancelled' || normalized == 'canceled') {
      return _StepRow(
        title: 'Cancelado',
        subtitle: 'El pedido fue cancelado.',
        active: true,
        color: Colors.red,
      );
    }

    final activeIndex = _indexByStatus[normalized] ?? 0;

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            title: _steps[i].$1,
            subtitle: _steps[i].$2,
            active: i <= activeIndex,
            color: AppColors.primaryColor,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final Color color;

  const _StepRow({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            color: active ? color : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.black : Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: active ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
