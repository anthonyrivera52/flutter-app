import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/view/active_order_screen.dart';

class NewOrderNotificationScreen extends StatelessWidget {
  NewOrderNotificationScreen({super.key});

  // Mapa global para poder manipular la cámara
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    // No usamos Consumer aquí para evitar reconstrucciones innecesarias del mapa
    final newOrderViewModel = Provider.of<NewOrderViewModel>(context);
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);

    final order = newOrderViewModel.currentNewOrder;

    if (order == null) {
      // Si la orden es nula (ej. fue rechazada o aún no se carga), vuelve a la pantalla de inicio
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Configura los marcadores del mapa
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('restaurantLocation'),
        position: order.restaurantLocation,
        infoWindow: InfoWindow(title: order.restaurantName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('customerLocation'),
        position: order.customerLocation,
        infoWindow: const InfoWindow(title: 'Cliente'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    // Ajusta la vista del mapa para que ambos puntos sean visibles
    void _fitMapToBounds(LatLng loc1, LatLng loc2) {
      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          loc1.latitude < loc2.latitude ? loc1.latitude : loc2.latitude,
          loc1.longitude < loc2.longitude ? loc1.longitude : loc2.longitude,
        ),
        northeast: LatLng(
          loc1.latitude > loc2.latitude ? loc1.latitude : loc2.latitude,
          loc1.longitude > loc2.longitude ? loc1.longitude : loc2.longitude,
        ),
      );
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
    }

    // Callback para cuando el mapa se ha creado
    void onMapCreated(GoogleMapController controller) {
      _mapController = controller;
      // Ajusta la cámara para ver ambos marcadores (simulado, idealmente necesitarías la ubicación actual)
      _fitMapToBounds(order.restaurantLocation, order.customerLocation);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: onMapCreated,
              initialCameraPosition: CameraPosition(
                target: order.restaurantLocation, // Centrado inicial en el restaurante
                zoom: 12.0,
              ),
              markers: markers,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de Pedido: ${order.orderType}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Origen: ${order.restaurantName}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          Text(order.restaurantAddress,
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Destino: ${order.customerAddress}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                          Icons.attach_money,
                          'Ganancia Estimada',
                          '\$${order.estimatedEarnings.toStringAsFixed(2)}'),
                      _buildInfoChip(Icons.timer, 'Tiempo Estimado',
                          '${order.estimatedTimeMinutes} min'),
                      _buildInfoChip(Icons.directions, 'Distancia',
                          '${order.distanceKm.toStringAsFixed(1)} km'),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: newOrderViewModel.isLoading
                              ? null
                              : () async {
                                await newOrderViewModel.rejectOrder(order.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Pedido rechazado.')),
                                );
                                Navigator.pop(context); // Vuelve a la pantalla principal
                              
                              },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: newOrderViewModel.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Rechazar',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: newOrderViewModel.isLoading
                              ? null
                              : () async {
                                  await newOrderViewModel.acceptOrder(order.id);
                                  activeOrderViewModel.setActiveOrder(order); // Pasa la orden al ViewModel de orden activa
                                  newOrderViewModel.clearCurrentNewOrder(); // Limpia la orden del ViewModel de nueva orden
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ActiveOrderScreen()),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: newOrderViewModel.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Aceptar',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.deepPurple),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}