import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart'; // Importa el ViewModel de la orden activa
import 'package:delivery_app_mvvm/model/location_data.dart'; // Importa el modelo de datos de ubicación

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController; // Ahora puede ser nulo al inicio
  Set<Marker> _markers = {}; // Para el marcador del repartidor

  // Posición inicial del mapa, un valor por defecto antes de tener la ubicación real
  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(6.195618, -75.575971), // Una ubicación central por defecto (Sabaneta)
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // No necesitamos _initializeOrderDetails aquí, el Consumer se encargará
    // de actualizar el mapa cuando la ubicación del repartidor cambie.
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Opcional: Centrar el mapa en la ubicación inicial del repartidor si ya la tenemos
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);
    if (activeOrderViewModel.currentDriverLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(activeOrderViewModel.currentDriverLocation!.toLatLng()),
      );
    }
  }

  // Método para actualizar el marcador del repartidor en el mapa
  void _updateDriverLocationMarker(LocationData? driverLocation) {
    _markers.clear();
    if (driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driverLocation'),
          position: driverLocation.toLatLng(),
          infoWindow: const InfoWindow(title: 'Tu Posición'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      // Opcional: Mover la cámara del mapa para seguir al repartidor
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(driverLocation.toLatLng()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en NewOrderViewModel y ActiveOrderViewModel
    final newOrderViewModel = Provider.of<NewOrderViewModel>(context);
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context); // Escuchamos para la ubicación

    // Muestra la pantalla de notificación de nueva orden si hay una disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newOrderViewModel.currentNewOrder != null &&
          newOrderViewModel.currentNewOrder!.status == 'pending') {
        Navigator.pushNamed(context, '/new_order');
        // Limpiamos la orden pendiente después de navegar para evitar re-navegación
        // Esta línea es importante para que no se active repetidamente el pushNamed.
        newOrderViewModel.clearCurrentOrder();
      }
    });

    // Actualiza el marcador del repartidor cada vez que la ubicación cambie
    // Esto se llamará con cada notifyListeners() de activeOrderViewModel
    _updateDriverLocationMarker(activeOrderViewModel.currentDriverLocation);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery App - Repartidor'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sección del mapa
          Expanded(
            flex: 2, // Toma 2/3 del espacio
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _kInitialCameraPosition,
              markers: _markers, // Muestra el marcador del repartidor
              myLocationButtonEnabled: true,
              myLocationEnabled: true, // Esto no funcionará con mocks directamente, pero es buena práctica
            ),
          ),
          // Sección de controles y mensajes
          Expanded(
            flex: 1, // Toma 1/3 del espacio
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delivery_dining, size: 50, color: Colors.deepPurple),
                  const SizedBox(height: 10),
                  const Text(
                    'Esperando nuevos pedidos...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    newOrderViewModel.isLoading
                        ? 'Buscando órdenes...'
                        : (newOrderViewModel.errorMessage ?? ''),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: newOrderViewModel.isLoading
                        ? null
                        : () {
                            newOrderViewModel.fetchNewOrder();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Buscando nuevos pedidos...')),
                            );
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Buscar Pedidos'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}