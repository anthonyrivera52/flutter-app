// lib/view/home_screen.dart

import 'dart:ui';

import 'package:delivery_app_mvvm/widget/new_order_alert_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/view/active_order_screen.dart'; // <--- IMPORT YOUR ACTIVE ORDER SCREEN

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Controls the driver's online/offline status and visibility of "Esperando..." / Alert
  bool isSearchDelivery = false;

  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(6.195618, -75.575971), // Sabaneta, Antioquia, Colombia
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
  }

  /// Called when the Google Map is created.
  /// Sets the map controller and animates the camera to the driver's current location if available.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);
    if (activeOrderViewModel.currentDriverLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(activeOrderViewModel.currentDriverLocation!.toLatLng()),
      );
    }
  }

  /// Updates the driver's location marker on the map.
  /// Clears existing markers and adds a new one for the driver's position.
  /// Animates the camera to the new location.
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
      // Animates camera only if map controller is available
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(driverLocation.toLatLng()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access view models using Provider
    final newOrderViewModel = Provider.of<NewOrderViewModel>(context);
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context);

    // Update the driver's marker whenever the location changes
    _updateDriverLocationMarker(activeOrderViewModel.currentDriverLocation);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // No shadow for a flat design
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome message for the driver
                Text(
                  'Bienvenido: Admin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 3.0), // Spacing
                Row(
                  children: [
                    // Status indicator circle (red for inactive, green for active)
                    Container(
                      width: 10.0,
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: !isSearchDelivery ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8.0), // Spacing
                    // Status text
                    Text(
                      !isSearchDelivery ? 'Estado: Inactivo' : 'Estado: Activo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 3.0), // Spacing
              ],
            ),
          ],
        ),
        actions: [
          // "Detener" button visible when the driver is online
          Visibility(
            visible: isSearchDelivery,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isSearchDelivery = false; // Go offline
                    newOrderViewModel.clearCurrentNewOrder(); // Clear any pending orders
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700], // Red color for stopping
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                  elevation: 5, // Subtle shadow
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.stop), // Stop icon
                label: const Text('Detener'), // Text label
              ),
            ),
          ),
          // "Ver Orden Activa" icon button visible only if there's an active order
          Visibility(
            visible: activeOrderViewModel.activeOrder != null,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(Icons.delivery_dining, color: Colors.blueAccent, size: 30),
                onPressed: () {
                  // Navigate to the ActiveOrderScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActiveOrderScreen(),
                    ),
                  );
                },
                tooltip: 'Ver Orden Activa', // Tooltip for accessibility
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map section, occupying the full background
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _kInitialCameraPosition,
            markers: _markers,
            myLocationButtonEnabled: true, // Shows the button to center on user's location
            zoomControlsEnabled: true, // Shows zoom in/out controls
            myLocationEnabled: true, // Shows the blue dot for user's location
          ),
          // Bottom aligned UI for controls and new order alerts
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<NewOrderViewModel>(
                builder: (context, vm, child) {
                  // --- Display New Order Alert Widget ---
                  if (vm.currentNewOrder != null && vm.currentNewOrder!.status == 'pending') {
                    return NewOrderAlertWidget(
                      order: vm.currentNewOrder!,
                      onAccept: () async {
                        debugPrint('Orden Aceptada: ${vm.currentNewOrder!.id}');
                        await vm.updateOrderStatus(vm.currentNewOrder!.id, 'accepted');
                        activeOrderViewModel.setActiveOrder(vm.currentNewOrder!);
                        vm.clearCurrentNewOrder(); // Clear the pending order alert
                        // Navigate to the ActiveOrderScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveOrderScreen(),
                          ),
                        );
                      },
                      onDecline: () async {
                        debugPrint('Orden Declinada: ${vm.currentNewOrder!.id}');
                        await vm.updateOrderStatus(vm.currentNewOrder!.id, 'rejected');
                        vm.clearCurrentNewOrder(); // Clear the pending order alert
                      },
                    );
                  }
                  // --- Display Connection Error Message ---
                  else if (vm.errorMessage != null) {
                    return Card(
                      color: Colors.red[50], // Light red background
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Rounded corners for the card
                      ),
                      elevation: 5, // Shadow for depth
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Error de Conexión: ${vm.errorMessage!}',
                              style: TextStyle(color: Colors.red[700], fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                vm.fetchNewOrder(); // Retry fetching orders
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700], // Blue for action
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30), // Pill-shaped button
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // --- Display Active Order Details ---
                  else if (activeOrderViewModel.activeOrder != null) {
                    return Card(
                      color: Colors.lightBlue[50], // Light blue background
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Rounded corners
                      ),
                      elevation: 5, // Shadow
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
                            Text('Cliente: ${activeOrderViewModel.activeOrder!.customerName}', style: const TextStyle(fontSize: 16)),
                            Text('Dirección: ${activeOrderViewModel.activeOrder!.customerAddress}', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to the ActiveOrderScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ActiveOrderScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 3,
                              ),
                              child: const Text('Ver Detalles de Orden Activa'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // --- Display "¡CONECTARSE!" button or "Esperando..." state ---
                  else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isSearchDelivery)
                          // "¡CONECTARSE!" button when driver is offline
                          ElevatedButton.icon(
                            onPressed: vm.isLoading // Disable button if currently loading
                                ? null
                                : () {
                                    setState(() {
                                      isSearchDelivery = true; // Set driver status to online
                                    });
                                    vm.fetchNewOrder(); // Start fetching for new orders
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('¡CONECTARSE!'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700], // Green for positive action
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50), // Fully rounded button
                              ),
                              elevation: 8, // Prominent shadow
                            ),
                          )
                        else
                          // "Esperando nuevas órdenes..." display when driver is online and waiting
                          Card(
                            color: Colors.white,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Show loading indicator or search icon
                                  if (vm.isLoading)
                                    const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                    )
                                  else
                                    const Icon(Icons.search, size: 40, color: Colors.blueGrey),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Esperando nuevas órdenes...',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.blueGrey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Te avisaremos cuando haya una entrega disponible.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
