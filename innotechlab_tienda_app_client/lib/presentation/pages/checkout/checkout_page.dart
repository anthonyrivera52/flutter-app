// presentation/pages/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart';
import 'package:flutter_app/presentation/provider/checkout_provider.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class CheckoutPageModal extends ConsumerStatefulWidget {
  const CheckoutPageModal({super.key});

  @override
  ConsumerState<CheckoutPageModal> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPageModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  double? _userLatitude;
  double? _userLongitude;

  bool _callWhenArrive = false;
  bool _leaveAtDoor = true; // Default as checked
  bool _dontRingBell = false;

  @override
  void initState() {
    super.initState();
    // Puedes inicializar la dirección con un valor por defecto o dejarla vacía.
    _addressController.text = 'Oderstrasse 12A, 12030, Berlin'; // Dirección por defecto
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Handles getting the current user's location using Geolocator.
  /// Requests permissions if not granted and updates the address controller.
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(
              'Permiso de ubicación denegado. No se puede obtener la ubicación.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            'Permiso de ubicación denegado permanentemente. Habilita desde la configuración.');
        return;
      }

      // Get the current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _addressController.text =
            'Lat: ${_userLatitude!.toStringAsFixed(4)}, Lon: ${_userLongitude!.toStringAsFixed(4)} (Ubicación GPS)';
      });
      _showSnackBar('Ubicación obtenida con éxito!');
    } catch (e) {
      _showSnackBar('Error al obtener ubicación: $e');
    }
  }

  /// Shows a SnackBar message at the bottom of the screen.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Handles the order placement logic.
  /// Validates the form and cart, then simulates a successful order.
  void _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_addressController.text.isEmpty) {
        _showSnackBar('Por favor, ingresa una dirección o obtén tu ubicación.');
        return;
      }

      // If the user hasn't used GPS but has manually entered the address,
      // _userLatitude and _userLongitude will be null.
      // You can decide how to handle this:
      // 1. Always require GPS.
      // 2. Attempt to geocode the manual address to lat/lon (would require a geocoding service).
      // 3. Simply use the text address for the order.
      // For now, if lat/lon are null, only the text address will be used.
      if (_userLatitude == null || _userLongitude == null) {
        print(
            'Advertencia: La orden se realizará con la dirección de texto, no con coordenadas GPS.');
      }

      ref.read(checkoutProvider.notifier);
      final cartItems = ref.read(cartProvider).cartItems;
      ref.read(cartProvider).cartItems.fold(
            0.0,
            (total, item) => total + (item.quantity * item.price),
          );

      if (cartItems.isEmpty) {
        _showSnackBar('El carrito está vacío. Agrega productos antes de pagar.');
        return;
      }

      // Simulate a successful order for now
      final success = true; // In a real app, this would be the result of your order API call

      if (success) {
        ref.read(cartProvider.notifier).clearCart(); // Clear cart after successful order
        showInfoToast(
          context, 
          message: "Orden Creada.",
          backgroundColor: AppColors.infoColor,
          isDismissible: success,
          icon: Icons.payment,
          );
          context.go('/order-list');
        // context.go('/order-confirmation', extra: {
        //   'address': _addressController.text, // Pass the text address
        //   'userLatitude': _userLatitude,
        //   'userLongitude': _userLongitude,
        // }); // Pass data to order confirmation
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final cartState = ref.watch(cartProvider); // To display total amount

    // Calculate total price including delivery and tip for display
    final subtotal = cartState.cartItems.fold(
      0.0,
      (total, item) => total + (item.quantity * item.price),
    );
    const deliveryFee = 1.20; // Fixed delivery fee for now
    const tipAmount = 2.00; // Fixed tip amount for now
    final totalInclVAT = subtotal + deliveryFee + tipAmount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: Container(
        // Wraps SingleChildScrollView in a Container for styling
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          // Uses the theme's canvas color, usually white
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)), // Applies top border radius
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Section
                const Text(
                  'Dirección',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _addressController,
                        hintText: 'Ingresa tu dirección',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La dirección no puede estar vacía';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Shows a BottomSheet with address editing options
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext bc) {
                            return SafeArea(
                              child: Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.my_location),
                                    title: const Text('Usar mi ubicación actual'),
                                    onTap: () {
                                      _getCurrentLocation();
                                      Navigator.pop(context); // Closes the bottom sheet
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.map),
                                    title: const Text('Ver/Editar en el mapa'),
                                    onTap: () {
                                      Navigator.pop(context); // Closes the bottom sheet
                                      _showSnackBar('Integración con mapa (Google Maps) en desarrollo.');
                                      // Here would be the logic to open a map or navigate to a map screen.
                                      // For example: context.push('/map_picker');
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.edit_location),
                                    title: const Text('Establecer manualmente (Cerrar)'),
                                    onTap: () {
                                      Navigator.pop(context); // Closes the bottom sheet
                                      // Does nothing, allows the user to edit the text
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Text(
                        'Editar',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Details Section
                const Text(
                  'Detalles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Llamar al llegar',
                  _callWhenArrive,
                  (bool? value) {
                    setState(() {
                      _callWhenArrive = value!;
                    });
                  },
                ),
                _buildDetailRow(
                  'Dejar en la puerta',
                  _leaveAtDoor,
                  (bool? value) {
                    setState(() {
                      _leaveAtDoor = value!;
                    });
                  },
                ),
                _buildDetailRow(
                  "No tocar el timbre",
                  _dontRingBell,
                  (bool? value) {
                    setState(() {
                      _dontRingBell = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _notesController,
                  hintText: 'Aquí puedes añadir notas para el repartidor...',
                  validator: null, // No validation needed for notes
                ),
                const SizedBox(height: 24),

                // Orden Schedule Section
                const Text(
                  'Programar Orden',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Añadir fecha y hora de entrega',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Vouchers Section
                const Text(
                  'Cupones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Añadir código de cupón',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Add a tip Section
                const Text(
                  'Añadir una propina',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTipOption('1€'),
                    _buildTipOption('2€', isSelected: true),
                    _buildTipOption('4€'),
                    _buildTipOption('6€'),
                    _buildTipOption('8€'),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Agradece con una propina. El 100% es para los repartidores.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Method Section
                const Text(
                  'Método de pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.apple, size: 24), // Placeholder for Apple Pay icon
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Apple Pay',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Orden Summary Section
                const Text(
                  'Resumen del pedido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Número de pedido:'),
                    Text(
                      '#582394',
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Display Cart Items (summary)
                ...cartState.cartItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity} × ${item.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(item.quantity * item.price).toStringAsFixed(2)} €',
                          ),
                        ],
                      ),
                    )),
                // Static items from the image for demonstration
                _buildSummaryRow('2 × Brócoli Lorem Ipsum', '2,80 €'),
                _buildSummaryRow('1 × Zanahorias Lorem Ipsum', '1,60 €'),
                _buildSummaryRow('2 × Coca-Cola 0,30 L', '5,40 €'),
                _buildSummaryRow('2 × Berenjena texto aquí', '2,20 €'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildSummaryRow('Método de pago', 'Apple Pay', isBold: true),
                _buildSummaryRow('Envío', '${deliveryFee.toStringAsFixed(2)} €'),
                _buildSummaryRow('Propina', '${tipAmount.toStringAsFixed(2)} €'),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total incl. IVA',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${totalInclVAT.toStringAsFixed(2)} €',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Terms and Conditions
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    children: [
                      const TextSpan(text: 'Al realizar tu pedido, aceptas nuestros '),
                      TextSpan(
                        text: 'Términos y Condiciones',
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline),
                      ),
                      const TextSpan(text: ' y confirmas que has leído nuestros '),
                      TextSpan(
                        text: 'derechos de desistimiento',
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline),
                      ),
                      const TextSpan(text: ' y nuestra '),
                      TextSpan(
                        text: 'Política de Privacidad',
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3), // changes position of shadow
            ),
          ],
        ),
        child: checkoutState.isLoading
            ? const LoadingIndicator()
            : CustomButton(
                text: 'Confirmar y Pagar ${totalInclVAT.toStringAsFixed(2)} €',
                onPressed: _placeOrder,
                icon: const Icon(
                  Icons.credit_card,
                  size: 80,
                  color: AppColors.primaryColor,
                ), // Icon for payment
              ),
      ),
    );
  }

  /// Helper widget to build detail rows with a checkbox.
  Widget _buildDetailRow(String text, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
          SizedBox(
            width: 24, // Adjust size to match the image
            height: 24, // Adjust size to match the image
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces padding
              visualDensity: VisualDensity.compact, // Reduces padding
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build tip options.
  Widget _buildTipOption(String tip, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tip,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Helper widget to build summary rows.
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
