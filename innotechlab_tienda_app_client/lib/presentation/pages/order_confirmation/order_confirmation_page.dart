// presentation/pages/order_confirmation/order_confirmation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/core/services/region_config_service.dart';
import 'package:flutter_app/presentation/provider/order_confirmation_provider.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_app/shared/ui/map/osm_map_service.dart';

class OrderConfirmationPage extends ConsumerStatefulWidget {
  final double? userLatitude;
  final double? userLongitude;

  const OrderConfirmationPage({
    super.key,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  ConsumerState<OrderConfirmationPage> createState() =>
      _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage> {
  LatLng? _userLocation;
  LatLng? _storeLocation;
  late final OSMMapService _mapService;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapService = OSMMapService();
    _mapController = _mapService.mapController;
    _loadLatestOrderAndSetupMap();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestOrderAndSetupMap() async {
    final order = ref.read(orderConfirmationProvider).latestOrder;
    if (order != null) {
      setState(() {
        _userLocation = LatLng(order.shippingLatitude, order.shippingLongitude);
        _storeLocation = LatLng(order.storeLatitude, order.storeLongitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderConfirmationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Confirmado'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.go('/'); // Go back to home
          },
        ),
      ),
      body: orderState.isLoading
          ? const Center(child: LoadingIndicator())
          : orderState.latestOrder == null
          ? const Center(child: Text('No se encontró información del pedido.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade600,
                      size: 100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildOrderCodeCard(
                    context,
                    orderState.latestOrder?.verificationCode,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentInfoCard(
                    context,
                    orderState.latestOrder?.paymentInfo,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Tu pedido ha sido recibido!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ubicación de tu Pedido',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _userLocation != null && _storeLocation != null
                        ? _buildOrderMap()
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Productos del Pedido',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderState.latestOrder!.items.length,
                    itemBuilder: (context, index) {
                      final item = orderState.latestOrder!.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
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
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey.shade200,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                              ),
                                            ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      ),
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
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} x ${RegionConfigService.defaultConfig.formatPrice(item.priceAtPurchase)}',
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                RegionConfigService.defaultConfig.formatPrice(
                                  item.quantity * item.priceAtPurchase,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Estado del Pedido',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildOrderStatus(orderState.latestOrder!.status),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: 'Ver Mis Pedidos',
                    onPressed: () {
                      // Navigate to DashboardPage with Orders tab (index 1) selected
                      context.go('/', extra: {'initialTabIndex': 1});
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderCodeCard(BuildContext context, String? verificationCode) {
    // Preferir verificationCode sobre orderCode
    final displayCode = verificationCode?.isNotEmpty == true
        ? verificationCode
        : null;

    if (displayCode == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Código de Verificación',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  displayCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: displayCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Código copiado'),
                        ],
                      ),
                      backgroundColor: AppColors.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 22,
                ),
                tooltip: 'Copiar código',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Muéstralo al repartidor cuando llegue',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(BuildContext context, dynamic paymentInfo) {
    if (paymentInfo == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                paymentInfo.isOnline ? Icons.credit_card : Icons.payments,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Pago con ${paymentInfo.paymentMethodText}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                paymentInfo.isPaid ? Icons.check_circle : Icons.pending,
                color: paymentInfo.isPaid ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getPaymentStatusText(paymentInfo.paymentStatus),
                style: TextStyle(
                  color: paymentInfo.isPaid ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (paymentInfo.transactionId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Transacción: ${paymentInfo.transactionId}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
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
      default:
        return 'Estado desconocido';
    }
  }

  Widget _buildOrderStatus(String status) {
    Map<String, int> statusSteps = {
      'new': 0,
      'pending': 0,
      'preparing': 1,
      'ready_for_pickup': 2,
      'out_for_delivery': 3,
      'delivered': 4,
      'completed': 4,
    };
    int currentStep = statusSteps[status.toLowerCase()] ?? 0;

    return Column(
      children: [
        _buildStatusRow(
          'Pendiente',
          'Tu pedido está en espera de confirmación.',
          currentStep >= 0,
        ),
        _buildStatusRow(
          'Aceptado',
          'Tu pedido ha sido aceptado y se está preparando.',
          currentStep >= 1,
        ),
        _buildStatusRow(
          'En Procesamiento',
          'Tu pedido está siendo procesado en la tienda.',
          currentStep >= 2,
        ),
        _buildStatusRow(
          'Enviado',
          'Tu pedido ha salido de la tienda y va en camino.',
          currentStep >= 3,
        ),
        _buildStatusRow(
          'Entregado',
          'Tu pedido ha sido entregado exitosamente.',
          currentStep >= 4,
        ),
      ],
    );
  }

  Widget _buildStatusRow(String title, String subtitle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? AppColors.primaryColor : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? Colors.black : Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMap() {
    final centerLat = (_userLocation!.latitude + _storeLocation!.latitude) / 2;
    final centerLng =
        (_userLocation!.longitude + _storeLocation!.longitude) / 2;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 18,
      ),
      children: [
        _mapService.createTileLayer(),
        MarkerLayer(
          markers: [
            Marker(
              point: _userLocation!,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 20),
              ),
            ),
            Marker(
              point: _storeLocation!,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
