import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';

class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  List<bool> _itemChecked = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrderDetails();
    });
  }

  void _initializeOrderDetails() {
    final activeOrderViewModel =
        Provider.of<ActiveOrderViewModel>(context, listen: false);
    final order = activeOrderViewModel.activeOrder;
    if (order != null) {
      if (order.items != null) {
        _itemChecked = List<bool>.filled(order.items!.length, false);
      }
      // No es necesario llamar a _updateMarkers aquí, ya lo hará el Consumer en build.
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final activeOrderViewModel =
        Provider.of<ActiveOrderViewModel>(context, listen: false);
    final order = activeOrderViewModel.activeOrder;
    if (order != null) {
      _fitMapToAllMarkers(order, activeOrderViewModel.currentDriverLocation);
    }
  }

  // Actualiza este método para aceptar LocationData
  void _updateMarkers(Order order, LocationData? driverLocation) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('restaurantLocation'),
        position: order.restaurantLocation,
        infoWindow: InfoWindow(title: order.restaurantName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('customerLocation'),
        position: order.customerLocation,
        infoWindow: InfoWindow(title: 'Cliente: ${order.customerName}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    if (driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position:
              driverLocation.toLatLng(), // Usar la ubicación del repartidor
          infoWindow: const InfoWindow(title: 'Tu Ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
  }

  // Actualiza este método para aceptar LocationData
  void _fitMapToAllMarkers(Order order, LocationData? driverLocation) {
    // Solo intenta ajustar el mapa si hay una ubicación de repartidor válida
    if (_mapController == null || driverLocation == null) return;

    double minLat = driverLocation.latitude;
    double maxLat = driverLocation.latitude;
    double minLon = driverLocation.longitude;
    double maxLon = driverLocation.longitude;

    if (order.restaurantLocation.latitude < minLat) {
      minLat = order.restaurantLocation.latitude;
    }
    if (order.restaurantLocation.latitude > maxLat) {
      maxLat = order.restaurantLocation.latitude;
    }
    if (order.restaurantLocation.longitude < minLon) {
      minLon = order.restaurantLocation.longitude;
    }
    if (order.restaurantLocation.longitude > maxLon) {
      maxLon = order.restaurantLocation.longitude;
    }

    if (order.customerLocation.latitude < minLat) {
      minLat = order.customerLocation.latitude;
    }
    if (order.customerLocation.latitude > maxLat) {
      maxLat = order.customerLocation.latitude;
    }
    if (order.customerLocation.longitude < minLon) {
      minLon = order.customerLocation.longitude;
    }
    if (order.customerLocation.longitude > maxLon) {
      maxLon = order.customerLocation.longitude;
    }

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo realizar la llamada a $phoneNumber')),
      );
    }
  }

  Future<void> _openChat(String phoneNumber) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo chat con el cliente...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveOrderViewModel>(
      builder: (context, viewModel, child) {
        final order = viewModel.activeOrder;
        final driverLocation = viewModel.currentDriverLocation;

        // **Manejo inmediato de la orden nula:**
        // Si la orden es null, significa que ya ha sido completada y no hay nada que mostrar.
        // Se regresa a la pantalla anterior sin intentar renderizar nada más.
        if (order == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Verifica si la pantalla ya está desmontada para evitar errores
            if (mounted) {
              Navigator.pop(context);
            }
          });
          // Retorna un widget vacío o un Scaffold con un indicador de carga
          // mientras se procesa la navegación.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // **Asegúrate de que driverLocation no sea null antes de usarlo en _updateMarkers**
        _updateMarkers(order, driverLocation);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pedido en Curso'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: Column(
            children: [
              Expanded(
                flex: 2,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    // Fallback si driverLocation es null (ej. al inicio)
                    target: driverLocation?.toLatLng() ?? order.restaurantLocation,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                ),
              ),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado: ${order.status}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _buildSectionTitle('Origen: ${order.restaurantName}'),
                      Text(order.restaurantAddress,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      _buildSectionTitle('Destino: ${order.customerName}'),
                      Text(order.customerAddress,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(order.customerPhone),
                              icon: const Icon(Icons.call),
                              label: const Text('Llamar'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openChat(order.customerPhone),
                              icon: const Icon(Icons.chat),
                              label: const Text('Chatear'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                        ],
                      ),
                      if (order.items != null && order.items!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            _buildSectionTitle('Artículos a Recoger:'),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: order.items!.length,
                              itemBuilder: (context, index) {
                                return CheckboxListTile(
                                  title: Text(order.items![index]),
                                  value: _itemChecked[index],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _itemChecked[index] = value!;
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      const Divider(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () async {
                                  String nextStatus = _getNextStatus(order.status);
                                  if (nextStatus == 'delivered') {
                                    await viewModel.updateOrderStatus(nextStatus);
                                    viewModel.completeActiveOrder();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('¡Pedido entregado con éxito!')),
                                    );
                                    // No es necesario el Future.delayed aquí,
                                    // el `Navigator.pop` en el `if (order == null)`
                                    // se encargará de la navegación.
                                  } else {
                                    await viewModel.updateOrderStatus(nextStatus);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Estado actualizado a: $nextStatus')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: viewModel.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _getActionButtonText(order.status),
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case "accepted":
        return "En camino a recoger";
      case "picking_up":
        return "Marcar como Recogido";
      case "picked_up":
        return "En camino a entregar";
      case "delivering":
        return "Confirmar Entrega";
      default:
        return "Siguiente Paso";
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case "accepted":
        return "picking_up";
      case "picking_up":
        return "picked_up";
      case "picked_up":
        return "delivering";
      case "delivering":
        return "delivered";
      default:
        return currentStatus;
    }
  }
}