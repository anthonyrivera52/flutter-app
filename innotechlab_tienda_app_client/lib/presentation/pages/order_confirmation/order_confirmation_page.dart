// presentation/pages/order_confirmation/order_confirmation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Corrected import
import 'package:mi_tienda/presentation/providers/order_confirmation_provider.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:mi_tienda/domain/entities/order.dart'; // Import Order entity

class OrderConfirmationPage extends ConsumerStatefulWidget {
  final double? userLatitude;
  final double? userLongitude;

  const OrderConfirmationPage({
    super.key,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  ConsumerState<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? _userLocation;
  LatLng? _storeLocation;

  @override
  void initState() {
    super.initState();
    _loadLatestOrderAndSetupMap();
  }

  Future<void> _loadLatestOrderAndSetupMap() async {
    // For MVP, we'll fetch the latest order. In a real app, you'd pass the order ID.
    final provider = ref.read(orderConfirmationProvider);
    await provider.fetchLatestUserOrder();

    final order = ref.read(orderConfirmationProvider).latestOrder;
    if (order != null) {
      setState(() {
        _userLocation = LatLng(order.shippingLatitude, order.shippingLongitude);
        _storeLocation = LatLng(order.storeLatitude, order.storeLongitude);

        markers.add(
          Marker(
            markerId: const MarkerId('userLocation'),
            position: _userLocation!,
            infoWindow: const InfoWindow(title: 'Tu Ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        markers.add(
          Marker(
            markerId: const MarkerId('storeLocation'),
            position: _storeLocation!,
            infoWindow: const InfoWindow(title: 'Ubicación de la Tienda'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
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
                      Text(
                        '¡Tu pedido #${orderState.latestOrder!.id.substring(0, 8)} ha sido recibido!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ubicación de tu Pedido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _userLocation != null && _storeLocation != null
                            ? GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    (_userLocation!.latitude + _storeLocation!.latitude) / 2,
                                    (_userLocation!.longitude + _storeLocation!.longitude) / 2,
                                  ),
                                  zoom: 10,
                                ),
                                onMapCreated: (controller) {
                                  mapController = controller;
                                  // Optionally animate camera to show both points
                                  mapController?.animateCamera(
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
                                      padding: 50.0,
                                    ),
                                  );
                                },
                                markers: markers,
                                circles: {
                                  Circle(
                                    circleId: const CircleId('store_radius'),
                                    center: _storeLocation!,
                                    radius: 1000, // Example radius for store proximity
                                    fillColor: AppColors.primaryColor.withOpacity(0.1),
                                    strokeColor: AppColors.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                },
                              )
                            : const Center(child: CircularProgressIndicator()),
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
                                    child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.product.imageUrl!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/placeholder.png',
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
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
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

  Widget _buildOrderStatus(String status) {
    Map<String, int> statusSteps = {
      'pending': 0,
      'accepted': 1,
      'processing': 2,
      'shipped': 3,
      'delivered': 4,
    };
    int currentStep = statusSteps[status] ?? 0;

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
            color: isActive ? AppColors.accentColor : Colors.grey,
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
}

// order_confirmation_provider.dart (ViewModel)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/domain/usecases/order/get_user_orders_usecase.dart';
import 'package:mi_tienda/core/errors/failures.dart';

class OrderConfirmationState {
  final bool isLoading;
  final Order? latestOrder;
  final String? errorMessage;

  OrderConfirmationState({this.isLoading = false, this.latestOrder, this.errorMessage});

  OrderConfirmationState copyWith({
    bool? isLoading,
    Order? latestOrder,
    String? errorMessage,
  }) {
    return OrderConfirmationState(
      isLoading: isLoading ?? this.isLoading,
      latestOrder: latestOrder ?? this.latestOrder,
      errorMessage: errorMessage,
    );
  }
}

final orderConfirmationProvider = StateNotifierProvider<OrderConfirmationNotifier, OrderConfirmationState>((ref) {
  return OrderConfirmationNotifier(
    getUserOrdersUseCase: ref.read(getUserOrdersUseCaseProvider),
  );
});

class OrderConfirmationNotifier extends StateNotifier<OrderConfirmationState> {
  final GetUserOrdersUseCase getUserOrdersUseCase;

  OrderConfirmationNotifier({required this.getUserOrdersUseCase}) : super(OrderConfirmationState());

  Future<void> fetchLatestUserOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await getUserOrdersUseCase(NoParams());
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (orders) {
        if (orders.isNotEmpty) {
          // Assume the first one is the latest or sort by created_at if necessary
          final latest = orders.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
          state = state.copyWith(isLoading: false, latestOrder: latest);
        } else {
          state = state.copyWith(isLoading: false, latestOrder: null, errorMessage: 'No se encontraron pedidos.');
        }
      },
    );
  }
}

// get_user_orders_usecase.dart (Domain Use Case)
import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/domain/repositories/order_repository.dart';

class GetUserOrdersUseCase implements UseCase<List<Order>, NoParams> {
  final OrderRepository repository;
  GetUserOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Order>>> call(NoParams params) async {
    return await repository.getUserOrders();
  }
}

final getUserOrdersUseCaseProvider = Provider<GetUserOrdersUseCase>((ref) {
  return GetUserOrdersUseCase(ref.read(orderRepositoryProvider));
});