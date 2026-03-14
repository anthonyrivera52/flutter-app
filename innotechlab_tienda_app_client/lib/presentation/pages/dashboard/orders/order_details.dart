import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/provider/order_details_provider.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(orderDetailsProvider(widget.orderId).notifier)
          .fetchOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailsProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Estado del pedido')),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, OrderDetailsState state) {
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
                    .read(orderDetailsProvider(widget.orderId).notifier)
                    .fetchOrderDetails(widget.orderId),
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

    final formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(order.createdAt.toLocal());
    final userLocation = LatLng(
      order.shippingLatitude,
      order.shippingLongitude,
    );
    final storeLocation = LatLng(order.storeLatitude, order.storeLongitude);
    final markers = {
      Marker(
        markerId: const MarkerId('userLocation'),
        position: userLocation,
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('storeLocation'),
        position: storeLocation,
        infoWindow: const InfoWindow(title: 'Comercio'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    return RefreshIndicator(
      onRefresh: () => ref
          .read(orderDetailsProvider(widget.orderId).notifier)
          .fetchOrderDetails(widget.orderId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Pedido #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(formattedDate),
          const SizedBox(height: 4),
          Text(
            'Total: \$${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Entrega: ${order.shippingAddress}'),
          const SizedBox(height: 16),
          _StatusTimeline(status: order.status),
          const SizedBox(height: 16),

           // Sección de información del domiciliario (si está asignado)
           if (order.driverId != null) _buildDriverInfo(context, order),
           if (order.driverId != null) const SizedBox(height: 16),

           // Sección de desglose de costos
           _buildPaymentBreakdown(context, order),
           const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (userLocation.latitude + storeLocation.latitude) / 2,
                    (userLocation.longitude + storeLocation.longitude) / 2,
                  ),
                  zoom: 12,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: markers,
                circles: {
                  Circle(
                    circleId: const CircleId('store_radius_details'),
                    center: storeLocation,
                    radius: 1000,
                    fillColor: AppColors.primaryColor.withValues(alpha: 0.08),
                    strokeColor: AppColors.primaryColor,
                    strokeWidth: 1,
                  ),
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
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
                          errorBuilder: (context, error, stackTrace) =>
                              _imageFallback(),
                        )
                      : _imageFallback(),
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
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }


  Widget _buildDriverInfo(BuildContext context, Orden order) {
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
        onTap: () {
          // Navegar a chat con repartidor
        },
      ),
    );
  }

  Widget _buildPaymentBreakdown(BuildContext context, Orden order) {
    final subtotal = order.subtotalAmount ?? order.totalAmount;
    final shipping = order.shippingAmount ?? 0.0;
    final tax = order.taxIvaAmount ?? 0.0;
    final tip = order.tipAmount ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Pago',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Envío'),
                Text('\$${shipping.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Impuestos'),
                Text('\$${tax.toStringAsFixed(2)}'),
              ],
            ),
            if (tip > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Propina'),
                  Text('\$${tip.toStringAsFixed(2)}'),
                ],
              ),
            ],
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
          ],
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    if (normalized == 'cancelled') {
      return _statusRow(
        title: 'Cancelado',
        subtitle: 'El pedido fue cancelado.',
        active: true,
        activeColor: Colors.red,
      );
    }

    final steps = <_StepData>[
      const _StepData(title: 'Pendiente', subtitle: 'Esperando confirmación'),
      const _StepData(
        title: 'Aceptado',
        subtitle: 'Pedido confirmado por la tienda',
      ),
      const _StepData(
        title: 'Preparando',
        subtitle: 'Estamos preparando tu pedido',
      ),
      const _StepData(title: 'En camino', subtitle: 'El pedido va en ruta'),
      const _StepData(title: 'Entregado', subtitle: 'Pedido completado'),
    ];

    final indexByStatus = {
      'pending': 0,
      'accepted': 1,
      'processing': 2,
      'shipped': 3,
      'delivered': 4,
      'completed': 4,
    };

    final activeIndex = indexByStatus[normalized] ?? 0;

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _statusRow(
            title: steps[i].title,
            subtitle: steps[i].subtitle,
            active: i <= activeIndex,
            activeColor: AppColors.primaryColor,
          ),
      ],
    );
  }

  Widget _statusRow({
    required String title,
    required String subtitle,
    required bool active,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            color: active ? activeColor : Colors.grey,
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

  /// Widget para mostrar el código de verificación del pedido
}

class _StepData {
  final String title;
  final String subtitle;

  const _StepData({required this.title, required this.subtitle});
}
