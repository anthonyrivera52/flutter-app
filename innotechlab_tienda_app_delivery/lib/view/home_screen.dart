// lib/view/home_screen.dart

import 'dart:ui';
import 'package:delivery_app_mvvm/domain/entities/user_status.dart';
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';
import 'package:delivery_app_mvvm/widget/new_order_alert_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/view/active_order_screen.dart'; // This might be used elsewhere
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart'; // Import AuthViewModel
import 'package:delivery_app_mvvm/view/auth_screen.dart'; // New AuthScreen import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Controls the driver's online/offline status and visibility of "Esperando..." / Alert
  bool isSearchDelivery = false; // This can now be managed by HomeViewModel's status

  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(6.195618, -75.575971), // Sabaneta, Antioquia, Colombia
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // HomeViewModel's initializeStatus is now called within MyApp via `..initializeStatus()`
    // and listens to AuthViewModel directly.
    // We still need to initialize map controller and potentially location here.
  }

  /// Called when the Google Map is created.
  /// Sets the map controller and animates the camera to the driver's current location if available.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // It's safer to get the provider after the build context is fully initialized.
    // If currentDriverLocation is only set *after* the map is created, you'll need to listen for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);
      if (activeOrderViewModel.currentDriverLocation != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(activeOrderViewModel.currentDriverLocation!.toLatLng()),
        );
      }
    });
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(driverLocation.toLatLng()),
      );
    }
  }

  // Method to show the AuthScreen as a modal
  void _showAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height for scrolling form
      builder: (context) {
        return const AuthScreen(); // Your new authentication screen
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access view models using Provider
    final newOrderViewModel = Provider.of<NewOrderViewModel>(context);
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context); // Get AuthViewModel

    // Update the driver's marker whenever the location changes
    _updateDriverLocationMarker(activeOrderViewModel.currentDriverLocation);

    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _kInitialCameraPosition,
              markers: _markers,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              myLocationEnabled: true,
            ),
          ),
          // Top Bar elements (always visible, regardless of auth state)
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Text(
                        '\$',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                      ),
                      Text(
                        '0',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Container()
                // Container(
                //   padding: const EdgeInsets.all(8.0),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(10),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.1),
                //         blurRadius: 5,
                //         offset: const Offset(0, 2),
                //       ),
                //     ],
                //   ),
                //   child: IconButton( // Added IconButton for logout
                //     icon: const Icon(Icons.logout),
                //     onPressed: () {
                //       authViewModel.signOut();
                //     },
                //   ),
                // ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 20,
            bottom: 400,
            child: 
              Align(
                alignment: Alignment.center,
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
                      else return const SizedBox.shrink(); // No alert or button to show
                    },
                  ),
                ),
              ), 
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Consumer<HomeViewModel>(
              builder: (context, homeViewModel, child) {
                // If not authenticated, show a simplified "Please log in" banner
                if (!authViewModel.isAuthenticated) {
                  return _buildLoginRequiredBanner(context);
                }
                // Otherwise, show the regular online/offline banners
                else if (homeViewModel.isLoading) {
                  return _buildLoadingBanner();
                } else if (homeViewModel.userStatus.status == UserConnectionStatus.offline) {
                  return _buildOfflineBanner(context, homeViewModel);
                } else {
                  return _buildOnlineBanner(context, homeViewModel);
                }
              },
            ),
          ),
          // New Order Alert (Overlaying everything, if applicable)
          // This should probably be controlled by newOrderViewModel
          // newOrderViewModel.showNewOrderAlert
          //     ? NewOrderAlertWidget(
          //         order: newOrderViewModel.currentOrder,
          //         onAccept: () {
          //           activeOrderViewModel.acceptOrder(newOrderViewModel.currentOrder!);
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(builder: (context) => ActiveOrderScreen()),
          //           );
          //           newOrderViewModel.hideAlert();
          //         },
          //         onReject: () {
          //           newOrderViewModel.rejectOrder(newOrderViewModel.currentOrder!);
          //         },
          //       )
          //     : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "You are not logged in.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Please log in or register to go online and receive orders.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showAuthModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Log In / Register',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),

        ],
      ),
    );
  }

  Widget _buildLoadingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text("Updating status...", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context, HomeViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            viewModel.userStatus.message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () {
                        // Handle calendar button press
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.attemptGoOnline();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Go Online',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        // Handle filter button press
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOnlineBanner(BuildContext context, HomeViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            viewModel.userStatus.message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () {
                        // Handle calendar button press
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.attemptGoOffline();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Go Offline',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        // Handle filter button press
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}