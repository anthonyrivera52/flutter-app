import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mi_tienda/domain/entities/order.dart'; // Assuming OrderItem is part of order.dart or imported separately
import 'package:mi_tienda/presentation/providers/order_details_provider.dart';
import 'package:mi_tienda/core/utils/app_colors.dart'; // For status colors and map circle
// import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart'; // If available

class OrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  LatLng? _storeLocation;

  @override
  void initState() {
    super.initState();
    // Fetch order details when the page is initialized
    // Use a post-frame callback to ensure ref is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(orderDetailsProvider(widget.orderId).notifier).fetchOrderDetails(widget.orderId);
      }
    });
  }

  void _updateMapMarkers(Order order) {
    if (!mounted) return;
    setState(() {
      _userLocation = LatLng(order.shippingLatitude, order.shippingLongitude);
      _storeLocation = LatLng(order.storeLatitude, order.storeLongitude);
      _markers.clear(); // Clear previous markers

      _markers.add(
        Marker(
          markerId: const MarkerId('userLocation'),
          position: _userLocation!,
          infoWindow: const InfoWindow(title: 'Tu Ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('storeLocation'),
          position: _storeLocation!,
          infoWindow: const InfoWindow(title: 'Ubicación de la Tienda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    // Animate camera to fit markers
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _userLocation!.latitude < _storeLocation!.latitude ? _userLocation!.latitude : _storeLocation!.latitude,
            _userLocation!.longitude < _storeLocation!.longitude ? _userLocation!.longitude : _storeLocation!.longitude,
          ),
          northeast: LatLng(
            _userLocation!.latitude > _storeLocation!.latitude ? _userLocation!.latitude : _storeLocation!.latitude,
            _userLocation!.longitude > _storeLocation!.longitude ? _userLocation!.longitude : _storeLocation!.longitude,
          ),
        ),
        padding: 50.0, // Padding around the bounds
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final orderDetailsState = ref.watch(orderDetailsProvider(widget.orderId));

    // Listen to state changes to update map markers when order data is available
    ref.listen<OrderDetailsState>(orderDetailsProvider(widget.orderId), (previous, next) {
      if (next.order != null && next.order != previous?.order) {
        _updateMapMarkers(next.order!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Pedido'),
      ),
      body: _buildBody(context, orderDetailsState),
    );
  }

  Widget _buildBody(BuildContext context, OrderDetailsState state) {
    if (state.isLoading && state.order == null) {
      return const Center(child: CircularProgressIndicator()); // Or LoadingIndicator()
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(orderDetailsProvider(widget.orderId).notifier).fetchOrderDetails(widget.orderId),
              child: const Text('Reintentar'),
            )
          ],
        ),
      );
    }

    final order = state.order;
    if (order == null) {
      return const Center(child: Text('No se encontró información del pedido.'));
    }
    
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedido #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Fecha: $formattedDate', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Total: \$${order.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Dirección de Envío: ${order.shippingAddress}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),

          Text(
            'Ubicación del Pedido',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: (_userLocation != null && _storeLocation != null)
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (_userLocation!.latitude + _storeLocation!.latitude) / 2,
                        (_userLocation!.longitude + _storeLocation!.longitude) / 2,
                      ),
                      zoom: 12, // Adjusted zoom
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Call _updateMapMarkers again if map was created after order loaded
                       if (state.order != null) _updateMapMarkers(state.order!);
                    },
                    markers: _markers,
                    circles: {
                      Circle(
                        circleId: const CircleId('store_radius_details'), // Unique ID
                        center: _storeLocation!,
                        radius: 1000, // Example radius
                        fillColor: AppColors.primaryColor.withOpacity(0.1),
                        strokeColor: AppColors.primaryColor,
                        strokeWidth: 1, // Thinner stroke
                      ),
                    },
                  )
                : const Center(child: Text("Cargando mapa...")), // Placeholder while locations are determined
          ),
          const SizedBox(height: 30),

          Text(
            'Productos del Pedido',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.product.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/placeholder.png', width: 60, height: 60, fit: BoxFit.cover),
                              )
                            : Image.asset(
                                'assets/images/placeholder.png', // Local placeholder
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${item.quantity} x \$${item.priceAtPurchase.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      Text('\$${(item.quantity * item.priceAtPurchase).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),

          Text(
            'Estado del Pedido',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildOrderStatus(context, order.status), // Pass context if needed by styles
        ],
      ),
    );
  }

  // Reused from OrderConfirmationPage (with minor adaptations if necessary)
  Widget _buildOrderStatus(BuildContext context, String status) {
    // Status definitions might vary, ensure these match your Order entity's possible statuses
    Map<String, int> statusSteps = {
      'pending': 0,
      'accepted': 1,       // Added based on typical flow
      'processing': 2,     // Renamed from 'in_progress' if needed
      'shipped': 3,        // Added based on typical flow
      'delivered': 4,      // Standard final status
      'cancelled': -1      // For cancelled orders
    };
    // If your Order entity uses 'completed' instead of 'delivered'
    // statusSteps['completed'] = 4;

    int currentStep = statusSteps[status.toLowerCase()] ?? 0;
    bool isCancelled = status.toLowerCase() == 'cancelled';

    if (isCancelled) {
      return _buildStatusRow(context, 'Cancelado', 'Este pedido ha sido cancelado.', true, isCancelled: true);
    }

    return Column(
      children: [
        _buildStatusRow(context, 'Pendiente', 'Tu pedido está en espera de confirmación.', currentStep >= 0),
        _buildStatusRow(context, 'Aceptado', 'El pedido ha sido aceptado.', currentStep >= 1),
        _buildStatusRow(context, 'En Procesamiento', 'Tu pedido está siendo preparado.', currentStep >= 2),
        _buildStatusRow(context, 'Enviado', 'Tu pedido ha sido enviado.', currentStep >= 3),
        _buildStatusRow(context, 'Entregado', 'Tu pedido ha sido entregado.', currentStep >= 4),
      ],
    );
  }

  Widget _buildStatusRow(BuildContext context, String title, String subtitle, bool isActive, {bool isCancelled = false}) {
    Color activeColor = isCancelled ? Colors.red : AppColors.accentColor; // Use accentColor from AppColors
    Color inactiveColor = Colors.grey;
    IconData icon = isActive ? (isCancelled ? Icons.cancel : Icons.check_circle) : Icons.radio_button_unchecked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isActive ? activeColor : inactiveColor, size: 28),
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
                    color: isActive ? (isCancelled ? Colors.red : Colors.black) : Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? (isCancelled ? Colors.red.shade700 : Colors.black87) : Colors.grey,
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
