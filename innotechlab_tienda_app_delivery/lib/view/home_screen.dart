import 'dart:async';
import 'dart:ui';
import 'package:delivery_app_mvvm/view/active_order_screen.dart';
import 'package:delivery_app_mvvm/view/auth_screen.dart';
import 'package:delivery_app_mvvm/widget/drawer/custom_app_drawer.dart';
import 'package:delivery_app_mvvm/widget/home_header.dart';
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

  @override
  void initState() {
    _mapController?.dispose();
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pickupCodeController.dispose();
    _deliveryCodeController.dispose();
    super.dispose();
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

    // // Update markers and polylines based on view model changes
    // // This part ensures map elements are always up-to-date.
    // // It's crucial for the map to re-render with new data.
    // _updateMarkers(activeOrderViewModel.activeOrder, activeOrderViewModel.currentDriverLocation);
    // _updatePolylines(activeOrderViewModel.activeOrder, activeOrderViewModel.currentDriverLocation);

    // [MODIFIED] Ensure map fits markers only if there's an active order or specific reason
    // This prevents unwanted re-zooming if driver just moves slightly without order.
    // if (activeOrderViewModel.activeOrder != null && activeOrderViewModel.currentDriverLocation != null) {
    //   _fitMapToAllMarkers(activeOrderViewModel.activeOrder!, activeOrderViewModel.currentDriverLocation);
    // } else if (activeOrderViewModel.activeOrder == null && activeOrderViewModel.currentDriverLocation != null) {
    //   if (_mapController != null && mounted) {
    //     // If no active order, just center on driver's location at a standard zoom
    //     _mapController!.animateCamera(
    //       CameraUpdate.newLatLngZoom(activeOrderViewModel.currentDriverLocation!.toLatLng(), 16.0),
    //     );
    //   }
    // }

    // Actualiza los marcadores y polilíneas basándose en el estado actual de los ViewModels.
    _updateMapElements(homeViewModel.currentDriverLocation, activeOrderViewModel.activeOrder);

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

    // final driverLocation = activeOrderViewModel.currentDriverLocation;
    return Scaffold(
      drawer: CustomAppDrawer(authViewModel: authViewModel),
      body: Stack(
          children: [
            // Background Map
            //Positioned.fill(
              // child: 
              GoogleMap(
                mapType: MapType.normal,
                // La posición inicial de la cámara utiliza la ubicación del driver del HomeViewModel
                // o una ubicación por defecto si aún no está disponible.
                initialCameraPosition: CameraPosition(
                  bearing: 192.8334901395799,
                  tilt: 59.440717697143555,
                  target: homeViewModel.currentDriverLocation != null
                      ? LatLng(homeViewModel.currentDriverLocation!.latitude,
                              homeViewModel.currentDriverLocation!.longitude)
                      : const LatLng(6.195618, -75.575971), // Sabaneta, Antioquia, Colombia por defecto
                  zoom: 14.4746,
                ),
                // Cuando el mapa se crea, guardamos el controlador y centramos la cámara si la ubicación ya existe.
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (homeViewModel.currentDriverLocation != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          homeViewModel.currentDriverLocation!.latitude,
                          homeViewModel.currentDriverLocation!.longitude,
                        ),
                        14.4746, // Zoom un poco más cercano al inicio
                      ),
                    );
                  }
                },
                markers: _markers, // Se actualiza dinámicamente en _updateMapElements
                polylines: _polylines, // Se actualiza dinámicamente en _updateMapElements
                zoomControlsEnabled: true,
                myLocationEnabled: true, // Muestra el punto azul de la ubicación actual del usuario
                myLocationButtonEnabled: true, // Habilita el botón para centrar en la ubicación del usuario
              ),
            // ),
            // --- INDICADOR DE CONECTIVIDAD ---
            if (!homeViewModel.hasInternet)
              Container(
                width: double.infinity,
                color: Colors.red[700],
                padding: const EdgeInsets.all(8.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.signal_wifi_off, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Sin conexión a Internet',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            // --- FIN INDICADOR DE CONECTIVIDAD ---

            // --- MOSTRAR UBICACIÓN ACTUAL DEL DRIVER ---
            // if (homeViewModel.currentDriverLocation != null)
            //   Container(
            //     width: double.infinity,
            //     color: Colors.blue[700],
            //     padding: EdgeInsets.all(8.0),
            //     child: Text(
            //       'Mi ubicación: Lat ${homeViewModel.currentDriverLocation!.latitude.toStringAsFixed(4)}, '
            //       'Lon ${homeViewModel.currentDriverLocation!.longitude.toStringAsFixed(4)}',
            //       style: TextStyle(color: Colors.white, fontSize: 14),
            //       textAlign: TextAlign.center,
            //     ),
            //   )
            // else if (homeViewModel.errorMessage != null && homeViewModel.errorMessage!.contains('ubicación'))
            //   Container(
            //     width: double.infinity,
            //     color: Colors.orange[700],
            //     padding: EdgeInsets.all(8.0),
            //     child: Text(
            //       'Error de ubicación: ${homeViewModel.errorMessage}',
            //       style: TextStyle(color: Colors.white, fontSize: 14),
            //       textAlign: TextAlign.center,
            //     ),
            //   )
            // else
            //   // Mensaje mientras se carga la ubicación inicial
            //   Container(
            //     width: double.infinity,
            //     color: Colors.blueGrey[700],
            //     padding: const EdgeInsets.all(8.0),
            //     child: const Text(
            //       'Buscando ubicación...',
            //       style: TextStyle(color: Colors.white, fontSize: 14),
            //       textAlign: TextAlign.center,
            //     ),
            //   ),
            // // --- FIN MOSTRAR UBICACIÓN ACTUAL ---

            // Header de Home (Tu widget existente)
            HomeHeader(
              userStatus: homeViewModel.userStatus,
              totalEarnings: homeViewModel.totalEarnings,
            ),

            // Indicador de carga si alguna operación está en curso
            if (homeViewModel.isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
              
                if (homeViewModel.hasInternet && 
                authViewModel.isAuthenticated && 
                homeViewModel.userStatus.status == UserConnectionStatus.online &&
                newOrderViewModel.currentNewOrder != null && 
                newOrderViewModel.currentNewOrder!.status == 'pending')
                  // New Order Alert (Floating in the middle)
                  Align(
                    alignment: Alignment.topRight,
                    child: SafeArea(
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
                                // Opcional: ajustar la cámara del mapa para mostrar la ruta completa de la orden
                                if (homeViewModel.currentDriverLocation != null && activeOrderViewModel.activeOrder != null) {
                                  _fitMapToOrderAndDriver(activeOrderViewModel.activeOrder!, homeViewModel.currentDriverLocation!);
                                }
                              },
                              onDecline: () async {
                                debugPrint('Orden Declinada: ${newOrderViewModel.currentNewOrder!.id}');
                                await newOrderViewModel.updateOrderStatus(newOrderViewModel.currentNewOrder!.id, 'rejected');
                                newOrderViewModel.clearCurrentNewOrder();
                              }, 
                              onReject: () { 
                                
                              },
                            );
                            
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  )
                else
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
        )
      //),
    );
  }

  // --- MÉTODOS AUXILIARES PARA EL MAPA Y LA ORDEN ---

  // Este método se encarga de actualizar los marcadores y polilíneas.
  // Se llama en el `build` para reaccionar a los cambios de estado del ViewModel.
  void _updateMapElements(LocationData? driverLocation, Order? activeOrder) {
    _markers = {}; // Limpia marcadores anteriores
    _polylines = {}; // Limpia polilíneas anteriores

    if (driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: LatLng(driverLocation.latitude, driverLocation.longitude),
          infoWindow: const InfoWindow(title: 'Mi Ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      // Opcional: Centrar el mapa en el driver si no hay orden activa
      // y si el mapa ya está creado. Esto puede causar saltos si el driver se mueve.
      // Generalmente, solo se centra al inicio o al aceptar una orden.
      if (_mapController != null && activeOrder == null && mounted) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(driverLocation.latitude, driverLocation.longitude), 16.0),
        );
      }
    }

    if (activeOrder != null) {
      // Marcador del restaurante
      _markers.add(
        Marker(
          markerId: MarkerId('restaurant_location_${activeOrder.id}'),
          position: LatLng(activeOrder.restaurantLocation.latitude, activeOrder.restaurantLocation.longitude),
          infoWindow: InfoWindow(title: 'Restaurante: ${activeOrder.restaurantName}', snippet: activeOrder.restaurantAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      // Marcador del cliente
      _markers.add(
        Marker(
          markerId: MarkerId('customer_location_${activeOrder.id}'),
          position: LatLng(activeOrder.customerLocation.latitude, activeOrder.customerLocation.longitude),
          infoWindow: InfoWindow(title: 'Cliente: ${activeOrder.customerName}', snippet: activeOrder.customerAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );

      // Dibujar la polilínea desde el driver -> restaurante -> cliente
      // Asegúrate de que las coordenadas del driver, restaurante y cliente estén disponibles.
      if (driverLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('order_route_${activeOrder.id}'),
            points: [
              LatLng(driverLocation.latitude, driverLocation.longitude),
              LatLng(activeOrder.restaurantLocation.latitude, activeOrder.restaurantLocation.longitude),
              LatLng(activeOrder.customerLocation.latitude, activeOrder.customerLocation.longitude),
            ],
            color: Colors.blueAccent,
            width: 5,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
          ),
        );
      }
      // Opcional: Ajustar la vista del mapa para incluir todos los marcadores de la orden.
      // Esto podría hacerse al aceptar la orden o cuando la ubicación del driver cambia
      // significativamente y el mapa necesita reajustarse para mostrar la ruta.
      // _fitMapToOrderAndDriver(activeOrder, driverLocation); // Descomentar si quieres este comportamiento
    }
  }

  // Función para ajustar el mapa a múltiples marcadores (driver, restaurante, cliente)
  Future<void> _fitMapToOrderAndDriver(Order order, LocationData driverLocation) async {
    String locationString = order.restaurantLocation as String;
      // Elimina los paréntesis y divide por la coma
      locationString = locationString.replaceAll('(', '').replaceAll(')', '');
      List<String> parts = locationString.split(',');

      // Convierte a double
      double latitude = double.parse(parts[0]);
      double longitude = double.parse(parts[1]);

      String locationCustomer = order.customerLocation as String;
      // Elimina los paréntesis y divide por la coma
      locationCustomer = locationCustomer.replaceAll('(', '').replaceAll(')', '');
      List<String> partsCustomer = locationCustomer.split(',');

      // Convierte a double
      double latitudeCustomer = double.parse(partsCustomer[0]);
      double longitudeCustomer = double.parse(partsCustomer[1]);
    if (_mapController == null) return;

    final LatLngBounds bounds = _boundsFromLatLngList([
      LatLng(driverLocation.latitude, driverLocation.longitude),
      LatLng(latitude, longitude),
      LatLng(latitudeCustomer, longitudeCustomer),
    ]);

    // Usamos `newLatLngBounds` para ajustar el zoom para que todos los puntos sean visibles.
    // El padding asegura que los marcadores no queden justo en el borde de la pantalla.
    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  // Función auxiliar para calcular los límites del mapa a partir de una lista de coordenadas
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
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
                      viewModel.goOnline();
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
                      viewModel.goOffline();
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
                  const Divider(height: 20),
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
                  const Divider(height: 20),
                  // Drag handle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Orden ID: ${order.id}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          order.status.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 20),
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

  // Método para obtener el color de estado (se mantiene de tu código original)
  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange; 
      case "accepted":
        return Colors.blue;
      case "arrived_at_restaurant":
        return Colors.purple;
      case "picked_up":
        return Colors.indigo;
      case "delivering":
        return Colors.teal;
      case "delivered":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

}