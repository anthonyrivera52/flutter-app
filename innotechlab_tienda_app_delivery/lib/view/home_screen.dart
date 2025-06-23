import 'dart:async';
import 'dart:ui';
import 'package:delivery_app_mvvm/view/auth_screen.dart';
import 'package:delivery_app_mvvm/widget/order_action_buttons_carousel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // Import for location services

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; // New set for polylines
  List<bool> _itemChecked = [];
  final TextEditingController _pickupCodeController = TextEditingController();
  final TextEditingController _deliveryCodeController = TextEditingController();

  StreamSubscription<Position>? _positionStreamSubscription; // For real-time location updates

  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(6.195618, -75.575971), // Sabaneta, Antioquia, Colombia
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndStartStream();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pickupCodeController.dispose();
    _deliveryCodeController.dispose();
    _positionStreamSubscription?.cancel(); // Cancel location stream
    super.dispose();
  }

  // Method to check location permission and start stream
  Future<void> _checkLocationPermissionAndStartStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled. Please enable them.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // [MODIFIED] Reduced location update frequency and improved accuracy
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, // [MODIFIED] Use high accuracy for more precise initial fix, but filtering below
        distanceFilter: 20, // [MODIFIED] Update only when moved 20 meters, helps stabilize
        timeLimit: Duration(seconds: 5) // [NEW] Add a time limit to prevent constant updates if distanceFilter isn't met
      ),
    ).listen((Position position) {
      final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context, listen: false);
      activeOrderViewModel.updateDriverLocation(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed, // Pass speed if available
        accuracy: position.accuracy, // Pass accuracy if available
      ));
      // Trigger map update based on new driver location
      _updateMapForLocationChange(activeOrderViewModel.activeOrder, activeOrderViewModel.currentDriverLocation);
    });
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

  // Modified: Separated marker and polyline updates for clarity and better control
  void _updateMapForLocationChange(Order? order, LocationData? driverLocation) {
    _updateMarkers(order, driverLocation);
    _updatePolylines(order, driverLocation);
    // [MODIFIED] Zoom the map to fit all markers when an order is active
    if (order != null && driverLocation != null) {
      _fitMapToAllMarkers(order, driverLocation);
    } else if (driverLocation != null) {
      // If no active order, just center on driver's location with a reasonable zoom
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(driverLocation.toLatLng(), 16.0),
      );
    }
    // No need to call setState here, as the view models' notifyListeners will rebuild the map.
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
    }
  }

  // Method to update polylines
  void _updatePolylines(Order? order, LocationData? driverLocation) {
    _polylines.clear();

    if (order == null || driverLocation == null) {
      return;
    }

    // Polyline from driver to restaurant when pending/accepted/arrived_at_restaurant/picking_up
    if (order.status == "pending" ||
        order.status == "accepted" ||
        order.status == "arrived_at_restaurant" ||
        order.status == "picking_up") {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driverToRestaurant'),
          points: [driverLocation.toLatLng(), order.restaurantLocation],
          color: Colors.red,
          width: 5,
        ),
      );
    }

    // Polyline from driver to customer when picked_up/delivering
    if (order.status == "picked_up" || order.status == "delivering") {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driverToCustomer'),
          points: [driverLocation.toLatLng(), order.customerLocation],
          color: Colors.blue,
          width: 5,
        ),
      );
    }
    // To ensure the map rebuilds with new polylines and markers, call setState
    // This is important because _polylines and _markers are state variables.
    if (mounted) {
      setState(() {});
    }
  }

  // [MODIFIED] Adjusted padding for map bounds and added more explicit checks
  void _fitMapToAllMarkers(Order order, LocationData? driverLocation) {
    if (_mapController == null || !mounted) {
      debugPrint("Map controller not ready or widget not mounted for fitting bounds.");
      return;
    }

    // Collect all relevant coordinates
    List<LatLng> points = [
      order.restaurantLocation,
      order.customerLocation,
    ];
    if (driverLocation != null) {
      points.add(driverLocation.toLatLng());
    }

    if (points.isEmpty) return; // Nothing to fit if no points

    // Calculate bounds
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (var point in points) {
      minLat = _min(minLat, point.latitude);
      maxLat = _max(maxLat, point.latitude);
      minLon = _min(minLon, point.longitude);
      maxLon = _max(maxLon, point.longitude);
    }

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapController != null) {
        // [MODIFIED] Increased padding for better visibility after zoom
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120.0));
      }
    });
  }

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
                      if (_pickupCodeController.text == '1234') {
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
                      if (_deliveryCodeController.text == '0000') {
                        if (mounted) Navigator.of(dialogContext).pop();
                        final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
                        homeViewModel.addEarnings(order.totalAmount);
                        print('Added \$${order.totalAmount} to total earnings.');
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
        return "Llegada al Restaurante";
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

  Future<void> _showPickupItemsModal(BuildContext context, Order order, ActiveOrderViewModel viewModel) async {
    if (order.items != null && order.items!.isNotEmpty) {
      setState(() {
        _itemChecked = List<bool>.filled(order.items!.length, false);
      });
    } else {
      _itemChecked = [];
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: order.items!.length,
                        itemBuilder: (context, index) {
                          final item = order.items![index];
                          return CheckboxListTile(
                            title: Text('${item.name} x${item.quantity}'),
                            value: _itemChecked[index],
                            onChanged: (bool? value) {
                              setStateModal(() {
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
                                if (mounted) Navigator.of(dialogContext).pop();
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
    final newOrderViewModel = Provider.of<NewOrderViewModel>(context);
    final activeOrderViewModel = Provider.of<ActiveOrderViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final homeViewModel = Provider.of<HomeViewModel>(context);

    // Update markers and polylines based on view model changes
    // This part ensures map elements are always up-to-date.
    // It's crucial for the map to re-render with new data.
    _updateMarkers(activeOrderViewModel.activeOrder, activeOrderViewModel.currentDriverLocation);
    _updatePolylines(activeOrderViewModel.activeOrder, activeOrderViewModel.currentDriverLocation);

    // [MODIFIED] Ensure map fits markers only if there's an active order or specific reason
    // This prevents unwanted re-zooming if driver just moves slightly without order.
    if (activeOrderViewModel.activeOrder != null && activeOrderViewModel.currentDriverLocation != null) {
      _fitMapToAllMarkers(activeOrderViewModel.activeOrder!, activeOrderViewModel.currentDriverLocation);
    } else if (activeOrderViewModel.activeOrder == null && activeOrderViewModel.currentDriverLocation != null) {
      if (_mapController != null && mounted) {
        // If no active order, just center on driver's location at a standard zoom
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(activeOrderViewModel.currentDriverLocation!.toLatLng(), 16.0),
        );
      }
    }

    // Initialize _itemChecked when an active order is set for the first time
    if (activeOrderViewModel.activeOrder != null &&
        (_itemChecked.isEmpty || _itemChecked.length != activeOrderViewModel.activeOrder!.items?.length)) {
      if (activeOrderViewModel.activeOrder!.items != null && activeOrderViewModel.activeOrder!.items!.isNotEmpty) {
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
          Positioned.fill( // Use Positioned.fill to make the map take all available space
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              // Initial camera position is based on driver location or default
              initialCameraPosition: driverLocation != null
                  ? CameraPosition(target: driverLocation.toLatLng(), zoom: 14.0)
                  : _kInitialCameraPosition,
              markers: _markers,
              polylines: _polylines, // Add polylines here
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
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
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                      ),
                      Text(
                        homeViewModel.totalEarnings.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Container() // Placeholder to balance the row if needed, or remove if not.
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
                        activeOrderViewModel.setActiveOrder(newOrderViewModel.currentNewOrder!);
                        newOrderViewModel.clearCurrentNewOrder();
                        // [NEW] Trigger map zoom immediately after accepting the order
                        if (activeOrderViewModel.currentDriverLocation != null && activeOrderViewModel.activeOrder != null) {
                          _fitMapToAllMarkers(activeOrderViewModel.activeOrder!, activeOrderViewModel.currentDriverLocation);
                        }
                      },
                      onDecline: () async {
                        debugPrint('Orden Declinada: ${newOrderViewModel.currentNewOrder!.id}');
                        await newOrderViewModel.updateOrderStatus(newOrderViewModel.currentNewOrder!.id, 'rejected');
                        newOrderViewModel.clearCurrentNewOrder();
                      },
                    );
                  }
                  return const SizedBox.shrink();
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
                  return _buildActiveOrderPanel(context, activeOrderViewModel);
                } else if (homeViewModel.userStatus.status == UserConnectionStatus.offline) {
                  return _buildOfflineBanner(context, homeViewModel);
                } else {
                  return _buildOnlineWaitingBanner(context, homeViewModel);
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
    final authViewModel = Provider.of<AuthViewModel>(context);
    return Material(
      color: Colors.white,
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
              authViewModel.isAuthenticated ? '¡Bienvenido!' : 'You are not logged in.',
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
          child: Container(
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
              padding: const EdgeInsets.all(16.0),
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