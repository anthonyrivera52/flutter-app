import 'dart:async'; 
import 'dart:ui';
import 'package:delivery_app_mvvm/view/auth_screen.dart';
import 'package:delivery_app_mvvm/widget/order_action_buttons_carousel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ViewModels
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';
import 'package:delivery_app_mvvm/viewmodel/new_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart';

// Models/Entities
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/domain/entities/user_status.dart';

// Widgets
import 'package:delivery_app_mvvm/widget/new_order_alert_widget.dart';

// --- No longer needed as it's integrated:
// import 'package:delivery_app_mvvm/view/active_order_screen.dart';
// import 'package:delivery_app_mvvm/view/auth_screen.dart'; // AuthScreen will be handled via modal

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // State specific to active order management, now within HomeScreenState
  List<bool> _itemChecked = [];
  final TextEditingController _pickupCodeController = TextEditingController();
  final TextEditingController _deliveryCodeController = TextEditingController();

  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(6.195618, -75.575971), // Sabaneta, Antioquia, Colombia
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // Initialize item checked list when an order becomes active.
    // This will be handled reactively in the build method or in a listener.
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pickupCodeController.dispose();
    _deliveryCodeController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);
      if (activeOrderViewModel.currentDriverLocation != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(activeOrderViewModel.currentDriverLocation!.toLatLng(), 16.0),
        );
      }
    });
  }

  void _updateMarkers(Order? order, LocationData? driverLocation) {
    _markers.clear();

    if (order != null) {
      // Restaurant marker
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurantLocation'),
          position: order.restaurantLocation,
          infoWindow: InfoWindow(title: order.restaurantName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Customer marker
      _markers.add(
        Marker(
          markerId: const MarkerId('customerLocation'),
          position: order.customerLocation,
          infoWindow: InfoWindow(title: 'Cliente: ${order.customerName}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Driver location marker (always show if available)
    if (driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driverLocation'),
          position: driverLocation.toLatLng(),
          infoWindow: const InfoWindow(title: 'Tu Posición'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Animate camera to driver location if active order is null,
      // otherwise, _fitMapToAllMarkers will handle camera.
      if (_mapController != null && mounted && order == null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(driverLocation.toLatLng()),
        );
      }
    }
  }

  void _fitMapToAllMarkers(Order order, LocationData? driverLocation) {
    if (_mapController == null || !mounted) {
      debugPrint("Map controller not ready or widget not mounted for fitting bounds.");
      return;
    }

    // Initialize with restaurant and customer locations
    double minLat = order.restaurantLocation.latitude;
    double maxLat = order.restaurantLocation.latitude;
    double minLon = order.restaurantLocation.longitude;
    double maxLon = order.restaurantLocation.longitude;

    minLat = _min(minLat, order.customerLocation.latitude);
    maxLat = _max(maxLat, order.customerLocation.latitude);
    minLon = _min(minLon, order.customerLocation.longitude);
    maxLon = _max(maxLon, order.customerLocation.longitude);

    // Include driver location if available
    if (driverLocation != null) {
      minLat = _min(minLat, driverLocation.latitude);
      maxLat = _max(maxLat, driverLocation.latitude);
      minLon = _min(minLon, driverLocation.longitude);
      maxLon = _max(maxLon, driverLocation.longitude);
    }

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );

    // Ensure camera animation happens after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
      }
    });
  }

  // Helper functions for min/max
  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showSnackBar('No se pudo realizar la llamada a $phoneNumber');
    }
  }

  Future<void> _openChat(String phoneNumber) async {
    _showSnackBar('Abriendo chat con el cliente...');
    // Implement chat opening logic (e.g., WhatsApp)
  }

  Future<void> _showPickupCodeModal(BuildContext context, Order order) async {
    _pickupCodeController.clear();
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ingresar Código de Recogida'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Por favor, ingresa el código proporcionado por ${order.restaurantName} para recoger el pedido.'),
                const SizedBox(height: 20),
                TextField(
                  controller: _pickupCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: activeOrderViewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirmar'),
              onPressed: activeOrderViewModel.isLoading
                  ? null
                  : () async {
                      if (_pickupCodeController.text == '1234') {// order.pickupCode) {
                        await activeOrderViewModel.updateOrderStatus("picking_up");
                        if (mounted) Navigator.of(dialogContext).pop();
                        _showSnackBar('Código validado. ¡Listo para recoger!');
                      } else {
                        _showSnackBar('Código incorrecto. Intenta de nuevo.');
                      }
                    },
            ),
          ],
        );
      },
    );
  }

    Future<void> _showDeliveryCodeModal(BuildContext context, Order order) async {
    _deliveryCodeController.clear();
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ingresar Código de Recogida'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Por favor, ingresa el código proporcionado por el usuerio para terminar el pedido.'),
                const SizedBox(height: 20),
                TextField(
                  controller: _deliveryCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: activeOrderViewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirmar'),
              onPressed: activeOrderViewModel.isLoading
                  ? null
                  : () async {
                      if (_deliveryCodeController.text == '0000') { // order.pickupCode
                        if (mounted) Navigator.of(dialogContext).pop();
                        final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
                        // Use totalAmount from the order to add to earnings
                        homeViewModel.addEarnings(order.totalAmount);
                        print('Added \\${order.totalAmount} to total earnings.');
                        await activeOrderViewModel.completeActiveOrder();
                      } else {
                        _showSnackBar('Código incorrecto. Intenta de nuevo.');
                      }
                    },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case "pending":
      case "accepted":
        return "Iendo al Restaurante";
      case "arrived_at_restaurant":
        return "Marcar como Recogido";
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

  String? _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case "pending":
      case "accepted":
        return "arrived_at_restaurant";
      case "arrived_at_restaurant":
        return "picked_up";
      case "picking_up":
        return "picked_up";
      case "picked_up":
        return "delivering";
      case "delivering":
        return "delivered";
      default:
        return null;
    }
  }

    // New: Modal for selecting items (replaces inline ListView.builder)
  Future<void> _showPickupItemsModal(BuildContext context, Order order, ActiveOrderViewModel viewModel) async {
    // Ensure _itemChecked is initialized to the correct size when opening the modal
    // A local state for the modal would be even cleaner if this were a separate widget.
    // For simplicity, we use _itemChecked from _HomeScreenState.
    if (order.items != null && order.items!.isNotEmpty) {
      setState(() {
        _itemChecked = List<bool>.filled(order.items!.length, false);
      });
    } else {
      _itemChecked = []; // No items
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to be full height
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder to manage inner state of the modal
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 16, // Adjust for keyboard
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Keep column size minimal
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Artículos de ${order.restaurantName}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Marca los artículos que has recogido:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (order.items != null && order.items!.isNotEmpty)
                    Flexible( // Use Flexible to prevent ListView.builder from overflowing
                      child: ListView.builder(
                        shrinkWrap: true, // Important for wrapping content
                        physics: const ClampingScrollPhysics(), // Prevent excessive scrolling
                        itemCount: order.items!.length,
                        itemBuilder: (context, index) {
                          final item = order.items![index];
                          return CheckboxListTile(
                            title: Text('${item.name} x${item.quantity}'),
                            value: _itemChecked[index],
                            onChanged: (bool? value) {
                              setStateModal(() { // Use setStateModal to update dialog's state
                                _itemChecked[index] = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              if (_itemChecked.contains(false)) {
                                _showSnackBar('Por favor, marca todos los artículos como recogidos.');
                              } else {
                                await viewModel.updateOrderStatus("picked_up");
                                if (mounted) Navigator.of(dialogContext).pop(); // Close modal
                                _showSnackBar('¡Pedido recogido! En camino al cliente.');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirmar Recogida',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to all relevant ViewModels
    final newOrderViewModel = Provider.of<NewOrderViewModel>(context);
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final homeViewModel = Provider.of<HomeViewModel>(context);

    // Update markers based on whether an active order exists or just driver location
    _updateMarkers(activeOrderViewModel.activeOrder, activeOrderViewModel.currentDriverLocation);

    // If there's an active order, fit the map to include all relevant points
    if (activeOrderViewModel.activeOrder != null && activeOrderViewModel.currentDriverLocation != null) {
      _fitMapToAllMarkers(activeOrderViewModel.activeOrder!, activeOrderViewModel.currentDriverLocation);
    } else if (activeOrderViewModel.activeOrder == null && activeOrderViewModel.currentDriverLocation != null) {
      // If no active order but we have driver location, ensure map is centered on driver
      if (_mapController != null && mounted) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(activeOrderViewModel.currentDriverLocation!.toLatLng(), 16.0),
        );
      }
    }

    // Initialize _itemChecked when an active order is set for the first time
    // or when the order changes (e.g., if a new order becomes active)
    if (activeOrderViewModel.activeOrder != null &&
        (_itemChecked.isEmpty || _itemChecked.length != activeOrderViewModel.activeOrder!.items?.length)) {
      if (activeOrderViewModel.activeOrder!.items != null && activeOrderViewModel.activeOrder!.items!.isNotEmpty) {
        // Use WidgetsBinding.instance.addPostFrameCallback to delay setState
        // and avoid "setState during build" if this is triggered by a provider update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _itemChecked = List<bool>.filled(activeOrderViewModel.activeOrder!.items!.length, false);
            });
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _itemChecked = [];
            });
          }
        });
      }
    }
    
    final driverLocation = activeOrderViewModel.currentDriverLocation;

    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          Positioned(
            child: activeOrderViewModel.activeOrder != null ?
            Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: driverLocation?.toLatLng() ?? activeOrderViewModel.activeOrder!.restaurantLocation,
                zoom: 14.0,
              ),
              markers: _markers, // This uses the _markers set
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
            ),
          )
          : GoogleMap(
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
                  child: Row(
                    children: [
                      const Text(
                        '\$',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                      ),
                      Text(
                        // Display total earnings from HomeViewModel
                        homeViewModel.totalEarnings.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Container()
              ],
            ),
          ),
          // New Order Alert (Floating in the middle)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  if (newOrderViewModel.currentNewOrder != null && newOrderViewModel.currentNewOrder!.status == 'pending') {
                    return NewOrderAlertWidget(
                      order: newOrderViewModel.currentNewOrder!,
                      onAccept: () async {
                        debugPrint('Orden Aceptada: ${newOrderViewModel.currentNewOrder!.id}');
                        await newOrderViewModel.updateOrderStatus(newOrderViewModel.currentNewOrder!.id, 'accepted');
                        // Set the accepted order as the active order
                        activeOrderViewModel.setActiveOrder(newOrderViewModel.currentNewOrder!);
                        newOrderViewModel.clearCurrentNewOrder(); // Clear the new order alert
                      },
                      onDecline: () async {
                        debugPrint('Orden Declinada: ${newOrderViewModel.currentNewOrder!.id}');
                        await newOrderViewModel.updateOrderStatus(newOrderViewModel.currentNewOrder!.id, 'rejected');
                        newOrderViewModel.clearCurrentNewOrder();
                      },
                    );
                  }
                  return const SizedBox.shrink(); // Hide if no new order
                },
              ),
            ),
          ),

          // Dynamic Bottom Panel (Login, Offline, Online, Active Order)
          Align(
            alignment: Alignment.bottomCenter,
            child: Builder(
              builder: (context) {
                if (!authViewModel.isAuthenticated) {
                  return _buildLoginRequiredBanner(context);
                } else if (homeViewModel.isLoading) {
                  return _buildLoadingBanner();
                } else if (activeOrderViewModel.activeOrder != null) {
                  // Display Active Order Panel if an order is active
                  return _buildActiveOrderPanel(context, activeOrderViewModel);
                } else if (homeViewModel.userStatus.status == UserConnectionStatus.offline) {
                  return _buildOfflineBanner(context, homeViewModel);
                } else { // User is authenticated and online, but no active order
                  return _buildOnlineWaitingBanner(context, homeViewModel); // Modified to be specific
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders for different states of the bottom panel ---

  Widget _buildLoginRequiredBanner(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context); // Asegura que escuche cambios
    return Material(
      color: Colors.white, // Fondo blanco para el modal
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
              authViewModel.isAuthenticated
                  ? '¡Bienvenido!'
                  : 'You are not logged in.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              authViewModel.isAuthenticated
                  ? 'Ya puedes recibir pedidos.'
                  : 'Please log in or register to go online and receive orders.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (!authViewModel.isAuthenticated)
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    builder: (context) => const AuthScreen(),
                  );
                },
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
          ],
        ),
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
                        _showSnackBar("Calendar feature not implemented yet.");
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
                        _showSnackBar("Filter feature not implemented yet.");
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

  Widget _buildOnlineWaitingBanner(BuildContext context, HomeViewModel viewModel) {
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
                        _showSnackBar("Calendar feature not implemented yet.");
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
                        _showSnackBar("Filter feature not implemented yet.");
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

   Widget _buildActiveOrderPanel(BuildContext context, ActiveOrderViewModel viewModel) {
    final order = viewModel.activeOrder!;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.20,
      maxChildSize: 0.45,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          // --- CORRECTED: Use a Column directly here, not a Row with double.infinity ---
          child: Container( // This Container provides the background and shadow
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0), // Apply padding here once
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: OrderActionButtonsCarousel(
                      viewModel: viewModel,
                      onMakePhoneCall: _makePhoneCall,
                      onOpenChat: _openChat,
                      onShowPickupItemsModal: _showPickupItemsModal,
                      onShowPickupCodeModal: _showPickupCodeModal,
                      onShowDeliveryCodeModal: _showDeliveryCodeModal,
                      onShowSnackBar: _showSnackBar,
                      getActionButtonText: _getActionButtonText,
                      getNextStatus: _getNextStatus,
                    ),
                  ),
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estado: ${order.status.replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildSectionTitle('Origen: ${order.restaurantName}'),
                  Text(order.restaurantAddress, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildSectionTitle('Destino: ${order.customerName}'),
                  Text(order.customerAddress, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildSectionTitle('Tipo de Pedido: ${order.orderType}'),
                  Text(
                    'Pago: \$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
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
}