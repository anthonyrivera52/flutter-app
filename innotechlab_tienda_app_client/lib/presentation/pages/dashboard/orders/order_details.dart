import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/core/services/region_config_service.dart';
import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/orders/presentation/viewmodels/driver_tracking_provider.dart';
import 'package:flutter_app/features/orders/presentation/viewmodels/order_details_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        GoogleMap,
        Marker,
        MarkerId,
        BitmapDescriptor,
        CameraPosition,
        InfoWindow,
        LatLng;
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Detalle del Pedido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {}, // Support/Help link
          ),
        ],
      ),
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
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
      'dd MMM yyyy, HH:mm',
      'es_ES',
    ).format(order.createdAt.toLocal());

    return RefreshIndicator(
      onRefresh: () => ref
          .read(orderDetailsProvider(widget.orderId).notifier)
          .fetchOrderDetails(widget.orderId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _OrderHeader(order: order, formattedDate: formattedDate),
            const SizedBox(height: 24),

            // Verification Code Section (Rappi-style)
            if (order.verificationCode != null &&
                order.verificationCode!.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Código de Verificación para el Repartidor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            order.verificationCode!,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              fontFamily: 'monospace',
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, size: 24),
                          tooltip: 'Copiar código',
                          onPressed: () {
                            // Clipboard functionality would go here in a real app
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Código copiado al portapapeles'),
                                duration: Duration(seconds: 1),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Map Section
            const Text(
              'Seguimiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _OrderMapSection(order: order),
            const SizedBox(height: 24),

            // Timeline Section
            _StatusTimeline(status: order.status),
            const SizedBox(height: 24),

            // Driver Info if any
            if (order.driverId != null) ...[
              const Text(
                'Repartidor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDriverInfo(context, order),
              const SizedBox(height: 24),
            ],

            // Order Items
            const Text(
              'Productos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => _OrderItemRow(item: item)),
            const SizedBox(height: 24),

            // Payment Summary
            const Text(
              'Resumen de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPaymentBreakdown(context, order),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo(BuildContext context, AppOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: order.driverPhotoUrl != null
                ? NetworkImage(order.driverPhotoUrl!)
                : null,
            child: order.driverPhotoUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName ?? 'Asignando repartidor...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (order.vehicleType != null)
                  Text(
                    '${order.vehicleType} • ${order.vehiclePlate ?? ""}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (order.driverPhone != null)
            IconButton(
              icon: const Icon(Icons.phone_in_talk, color: Colors.green),
              onPressed: () {}, // Call driver
            ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            onPressed: () {}, // Chat with driver
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(BuildContext context, AppOrder order) {
    final subtotal = order.subtotalAmount ?? order.totalAmount;
    final shipping = order.shippingAmount ?? 0.0;
    final tax = order.taxIvaAmount ?? 0.0;
    final tip = order.tipAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _PayDetailRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 8),
          _PayDetailRow(label: 'Costo de envío', value: shipping),
          const SizedBox(height: 8),
          _PayDetailRow(label: 'Impuestos (IVA)', value: tax),
          if (tip > 0) ...[
            const SizedBox(height: 8),
            _PayDetailRow(label: 'Propina', value: tip),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pagado',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                RegionConfigService.defaultConfig.formatPrice(
                  order.totalAmount,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final AppOrder order;
  final String formattedDate;

  const _OrderHeader({required this.order, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(order.status),
                  color: _statusColor(order.status),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _humanStatus(order.status),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Orden #${order.id.substring(0, 8)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.shippingAddress,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _humanStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente de Pago';
      case 'accepted':
        return 'Pedido Aceptado';
      case 'processing':
        return 'Preparando Pedido';
      case 'shipped':
        return 'En camino a tu casa';
      case 'delivered':
      case 'completed':
        return 'Pedido Entregado';
      case 'cancelled':
        return 'Pedido Cancelado';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top;
      case 'accepted':
        return Icons.check_circle;
      case 'processing':
        return Icons.restaurant;
      case 'shipped':
        return Icons.delivery_dining;
      case 'delivered':
      case 'completed':
        return Icons.verified;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
    }
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.product.imageUrl.isNotEmpty
                ? Image.network(
                    item.product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} un. x ${RegionConfigService.defaultConfig.formatPrice(item.priceAtPurchase)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            RegionConfigService.defaultConfig.formatPrice(
              item.quantity * item.priceAtPurchase,
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

class _PayDetailRow extends StatelessWidget {
  final String label;
  final double value;
  const _PayDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          RegionConfigService.defaultConfig.formatPrice(value),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
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
      return const _TimelineItem(
        title: 'Cancelado',
        subtitle: 'Tu pedido ha sido cancelado.',
        icon: Icons.cancel,
        color: Colors.red,
        isLast: true,
        isActive: true,
      );
    }

    final steps = [
      ('Pendiente', 'Recibimos tu orden', Icons.timer_outlined),
      ('Aceptado', 'La tienda ha confirmado', Icons.store),
      ('Preparando', 'Tu orden se está alistando', Icons.soup_kitchen),
      ('En camino', 'El repartidor va en ruta', Icons.delivery_dining),
      ('Entregado', '¡Disfruta tu pedido!', Icons.auto_awesome),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          return _TimelineItem(
            title: s.$1,
            subtitle: s.$2,
            icon: s.$3,
            color: i <= activeIndex
                ? AppColors.primaryColor
                : Colors.grey.shade300,
            isLast: i == steps.length - 1,
            isActive: i <= activeIndex,
            isCurrent: i == activeIndex,
          );
        }),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLast;
  final bool isActive;
  final bool isCurrent;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLast,
    required this.isActive,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive ? color : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black : Colors.grey.shade400,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isActive ? Colors.grey.shade600 : Colors.grey.shade300,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderMapSection extends ConsumerWidget {
  final AppOrder order;
  const _OrderMapSection({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLocation = LatLng(
      order.shippingLatitude,
      order.shippingLongitude,
    );
    final storeLocation = LatLng(order.storeLatitude, order.storeLongitude);
    final isShipped = order.status.toLowerCase() == 'shipped';
    final hasDriver = order.driverId != null;

    final driverLocAsync = (hasDriver && isShipped)
        ? ref.watch(driverTrackingProvider(order.driverId!))
        : null;

    // Convert from latlong2 to google_maps LatLng
    final driverPosition = driverLocAsync?.valueOrNull != null
        ? LatLng(
            driverLocAsync!.valueOrNull!.latitude,
            driverLocAsync.valueOrNull!.longitude,
          )
        : null;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('u'),
        position: userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('s'),
        position: storeLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      if (driverPosition != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: order.driverName ?? 'Repartidor'),
        ),
    };

    final center =
        driverPosition ??
        LatLng(
          (userLocation.latitude + storeLocation.latitude) / 2,
          (userLocation.longitude + storeLocation.longitude) / 2,
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 13),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: markers,
            ),
            if (driverPosition != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'En ruta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                onPressed: () {},
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for Stack alignment in Map
class PositionRectangle extends StatelessWidget {
  final double? bottom, right, left, top;
  final Widget child;
  const PositionRectangle({
    super.key,
    this.bottom,
    this.right,
    this.left,
    this.top,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Positioned(
    bottom: bottom,
    right: right,
    left: left,
    top: top,
    child: child,
  );
}
