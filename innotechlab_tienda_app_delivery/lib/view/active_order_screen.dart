import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'dart:math';

class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<bool> _itemChecked = [];
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrderDetails();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeOrderDetails() {
    final activeOrderViewModel =
        Provider.of<ActiveOrderViewModel>(context, listen: false);
    final order = activeOrderViewModel.activeOrder;
    if (order != null) {
      if (order.items != null && order.items!.isNotEmpty) {
        _itemChecked = List<bool>.filled(order.items!.length, false);
      } else {
        _itemChecked = [];
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (mounted) {
      final activeOrderViewModel =
          Provider.of<ActiveOrderViewModel>(context, listen: false);
      final order = activeOrderViewModel.activeOrder;
      // final driverLocation = activeOrderViewModel.currentDriverLocation;

      // Update markers immediately after map creation and data is available
      // if (order != null) { // We update markers even if driverLocation is null, just without driver marker
      //    _updateMarkers(order, driverLocation);
      // }

      // Fit map to markers only if controller is ready and initial data is there
      // if (order != null && driverLocation != null) {
      //   _fitMapToAllMarkers(order, driverLocation);
      // }
    }
  }

  // REMOVE setState() from here!
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
          position: driverLocation.toLatLng(),
          infoWindow: const InfoWindow(title: 'Tu Ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    // DO NOT call setState() here.
    // The Consumer in the build method will rebuild this widget when
    // ActiveOrderViewModel notifies, causing GoogleMap to refresh with
    // the updated _markers set.
  }

  void _fitMapToAllMarkers(Order order, LocationData? driverLocation) {
    if (_mapController == null || !mounted) {
      debugPrint("Map controller not ready or widget not mounted for fitting bounds.");
      return;
    }

    if (driverLocation == null) {
      debugPrint("Driver location is null, cannot fit all markers.");
      // If driver location is null, maybe just fit to restaurant/customer?
      // Or simply return if driver location is essential for the bounds.
      return;
    }

    double minLat = driverLocation.latitude;
    double maxLat = driverLocation.latitude;
    double minLon = driverLocation.longitude;
    double maxLon = driverLocation.longitude;

    minLat = min(minLat, order.restaurantLocation.latitude);
    maxLat = max(maxLat, order.restaurantLocation.latitude);
    minLon = min(minLon, order.restaurantLocation.longitude);
    maxLon = max(maxLon, order.restaurantLocation.longitude);

    minLat = min(minLat, order.customerLocation.latitude);
    maxLat = max(maxLat, order.customerLocation.latitude);
    minLon = min(minLon, order.customerLocation.longitude);
    maxLon = max(maxLon, order.customerLocation.longitude);

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
    _codeController.clear();
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
                  controller: _codeController,
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
                        color: Colors.greenAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirmar'),
              onPressed: activeOrderViewModel.isLoading
                  ? null
                  : () async {
                      if (_codeController.text == '1234') { // order.pickupCode) {
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

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveOrderViewModel>(
      builder: (context, viewModel, child) {
        final order = viewModel.activeOrder;
        // final driverLocation = viewModel.currentDriverLocation;

        if (order == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Call _updateMarkers directly here.
        // It modifies _markers, and since _markers is part of the state,
        // and this build method is being called because the ViewModel changed,
        // the GoogleMap will pick up the new _markers naturally.
        // _updateMarkers(order, driverLocation);

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
                    target: order.restaurantLocation,
                    zoom: 14.0,
                  ),
                  markers: _markers, // This uses the _markers set
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
                        'Estado: ${_getActionButtonText(order.status)}',
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
                      _buildSectionTitle('Tipo de Pedido: ${order.orderType}'),
                      Text(
                        'Pago: \$${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
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
                                final item = order.items![index];
                                return CheckboxListTile(
                                  title: Text('${item.name} x${item.quantity}'),
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
                                  String? nextStatus = _getNextStatus(order.status);

                                  if (nextStatus == 'arrived_at_restaurant') {
                                    await viewModel.updateOrderStatus(nextStatus!);
                                    _showPickupCodeModal(context, order);
                                  } else if (nextStatus == 'picked_up') {
                                    if (order.items != null && order.items!.isNotEmpty && _itemChecked.contains(false)) {
                                      _showSnackBar('Por favor, marca todos los artículos como recogidos.');
                                      return;
                                    }
                                    await viewModel.updateOrderStatus(nextStatus!);
                                    _showSnackBar('¡Pedido recogido! En camino al cliente.');
                                  } else if (nextStatus == 'delivered') {
                                    await viewModel.updateOrderStatus(nextStatus!);
                                    viewModel.completeActiveOrder();
                                    _showSnackBar('¡Pedido entregado con éxito!');
                                  } else if (nextStatus != null) {
                                    await viewModel.updateOrderStatus(nextStatus);
                                    _showSnackBar('Estado actualizado a: $nextStatus');
                                  } else {
                                    _showSnackBar('No hay un siguiente estado definido o la acción no es válida.');
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
}