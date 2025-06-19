// lib/view/home_screen.dart

import 'package:delivery_app_mvvm/widget/new_order_alert_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  bool isActiveDevliery = true;
  bool isSearchDelivery = false; // Estado para controlar la visibilidad del "Esperando nuevos pedidos..." o la alerta.

  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(6.195618, -75.575971), // Sabaneta, Antioquia, Colombia
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // Asegúrate de que los ViewModels estén suscritos al iniciar.
    // El stream de NewOrderViewModel se iniciará en su constructor,
    // pero si lo necesitas iniciar por un botón "Start", lo haces en el onPressed.
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);
    if (activeOrderViewModel.currentDriverLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(activeOrderViewModel.currentDriverLocation!.toLatLng()),
      );
    }
  }

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
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(driverLocation.toLatLng()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final newOrderViewModel = Provider.of<NewOrderViewModel>(context);
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context);

    // --- ¡ELIMINA ESTE BLOQUE DE CÓDIGO! ---
    // Muestra la pantalla de notificación de nueva orden si hay una disponible
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (newOrderViewModel.currentNewOrder != null &&
    //       newOrderViewModel.currentNewOrder!.status == 'pending') {
    //     Navigator.pushNamed(context, '/new_order');
    //     newOrderViewModel.clearCurrentNewOrder();
    //   }
    // });
    // -------------------------------------

    // Actualiza el marcador del repartidor cada vez que la ubicación cambie
    _updateDriverLocationMarker(activeOrderViewModel.currentDriverLocation);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Delivery App - Repartidor'),
        centerTitle: true,
      ),
      body: Stack( 
        // Mantén el Stack aquí para la superposición
        children: [
          // Sección del mapa (ocupa todo el espacio disponible)
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _kInitialCameraPosition,
            markers: _markers,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
          ),

          // --- UI de control y alerta de nueva orden ---
          // Usaremos Align para posicionar esta sección en la parte inferior de la pantalla.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<NewOrderViewModel>(
                builder: (context, vm, child) {
                  // Si hay un pedido nuevo, muestra la alerta
                  if (vm.currentNewOrder != null && vm.currentNewOrder!.status == 'pending') {
                    // Si el estado es "pending", mostramos la alerta de nuevo pedido
                    return NewOrderAlertWidget(
                      order: vm.currentNewOrder!,
                      onAccept: () async {
                        debugPrint('Orden Aceptada: ${vm.currentNewOrder!.id}');
                        // Actualiza el estado en Supabase
                        await vm.updateOrderStatus(vm.currentNewOrder!.id, 'accepted');
                        // Mueve el pedido a la orden activa
                        activeOrderViewModel.setActiveOrder(vm.currentNewOrder!);
                        // Limpiamos el pedido actual del newOrderViewModel (desaparece la alerta)
                        vm.clearCurrentNewOrder();
                      },
                      onDecline: () async {
                        debugPrint('Orden Declinada: ${vm.currentNewOrder!.id}');
                        // Actualiza el estado en Supabase
                        await vm.updateOrderStatus(vm.currentNewOrder!.id, 'rejected');
                        // Limpiamos el pedido actual del newOrderViewModel (desaparece la alerta)
                        vm.clearCurrentNewOrder();
                      },
                    );
                  } else if (vm.errorMessage != null) {
                    // Si hay un error, muestra un mensaje de error
                    return Card(
                      color: Colors.red[50],
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Error de Conexión: ${vm.errorMessage!}',
                              style: TextStyle(color: Colors.red[700], fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                vm.fetchNewOrder(); // Intenta reconectar
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Si no hay pedidos nuevos y no hay error, muestra el estado de espera
                  // o el botón "Start"
                  return Column(
                    mainAxisSize: MainAxisSize.min, // Que ocupe el mínimo espacio
                    children: [
                      // El botón "Start" solo se muestra si no estamos buscando (isSearchDelivery == false)
                      Visibility(
                        visible: !isSearchDelivery && activeOrderViewModel.activeOrder == null,
                        child: ElevatedButton.icon(
                          onPressed: vm.isLoading
                              ? null
                              : () {
                                  setState(() {
                                    isSearchDelivery = true; // Activa la búsqueda
                                    // isActiveDelivery se puede omitir si isSearchDelivery es suficiente
                                  });
                                  vm.fetchNewOrder(); // Inicia la escucha de órdenes
                                },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Searching Orders'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                      // El mensaje "Esperando nuevos pedidos..." solo si estamos buscando
                      // y no hay una orden activa ni una nueva orden pendiente.
                      Visibility(
                        visible: isSearchDelivery && vm.currentNewOrder == null && activeOrderViewModel.activeOrder == null,
                        child: Column(
                          children: [
                            const Icon(Icons.access_time, size: 50.0, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              vm.isLoading ? 'Buscando órdenes...' : 'Esperando nuevos pedidos...',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Mantente en línea para recibir notificaciones.',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      // Mostrar información de la orden activa si la hay
                      if (activeOrderViewModel.activeOrder != null)
                        Card(
                          color: Colors.lightBlue[50],
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Orden Activa',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                const SizedBox(height: 10),
                                Text('Cliente: ${activeOrderViewModel.activeOrder!.customerName}'),
                                Text('Dirección: ${activeOrderViewModel.activeOrder!.customerAddress}'),
                                // Puedes añadir más detalles de la orden activa y botones de acción (ej. "Navegar", "Completar")
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}