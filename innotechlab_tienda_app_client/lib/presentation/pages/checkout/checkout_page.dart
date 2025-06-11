// presentation/pages/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart';
import 'package:flutter_app/presentation/provider/checkout_provider.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
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
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Permiso de ubicación denegado. No se puede obtener la ubicación.')),
          );
          setState(() {
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Permiso de ubicación denegado permanentemente. Habilita desde la configuración.')),
        );
        setState(() {
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _addressController.text =
            'Lat: ${_userLatitude!.toStringAsFixed(4)}, Lon: ${_userLongitude!.toStringAsFixed(4)} (Ubicación GPS)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación obtenida con éxito!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    } finally {
      setState(() {
      });
    }
  }

  void _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_userLatitude == null || _userLongitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, obtén tu ubicación o ingresa una dirección completa.')),
        );
        return;
      }

      ref.read(checkoutProvider.notifier);
      final cartItems = ref.read(cartProvider).cartItems;
      ref.read(cartProvider).cartItems.fold(
            0.0,
            (total, item) => total + (item.quantity * item.price),
          );

      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El carrito está vacío. Agrega productos antes de pagar.')),
        );
        return;
      }

      // Simulate a successful order for now
      final success = true;

      if (success) {
        ref.read(cartProvider.notifier).clearCart(); // Clear cart after successful order
        context.go('/order-confirmation', extra: {
          'userLatitude': _userLatitude,
          'userLongitude': _userLongitude,
        }); // Pass data to order confirmation
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
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.close),
          //   onPressed: () => context.pop(),
          // ),
        ],
      ),
      body: Container( // Envuelve el SingleChildScrollView en un Container
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor, // Usa el color del canvas del tema, normalmente blanco
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // Aplica el borderRadius superior
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Section
                const Text(
                  'Address',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _addressController.text.isEmpty
                              ? 'Oderstrasse 12A, 12030, Berlin' // Placeholder from image
                              : _addressController.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Implement address edit functionality or GPS lookup
                          _getCurrentLocation();
                        },
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Details Section
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Call when you arrive',
                  _callWhenArrive,
                  (bool? value) {
                    setState(() {
                      _callWhenArrive = value!;
                    });
                  },
                ),
                _buildDetailRow(
                  'Leave at the door',
                  _leaveAtDoor,
                  (bool? value) {
                    setState(() {
                      _leaveAtDoor = value!;
                    });
                  },
                ),
                _buildDetailRow(
                  "Don't ring the bell",
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
                  hintText: 'Here you can add notes for the driver...',
                  validator: null, // No validation needed for notes
                ),
                const SizedBox(height: 24),

                // Orden Schedule Section
                const Text(
                  'Orden schedule',
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
                        'Add delivery date and time',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Vouchers Section
                const Text(
                  'Vouchers',
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
                        'Add voucher code',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Add a tip Section
                const Text(
                  'Add a tip',
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
                    'Say Thank You with a tip. 100% is for the riders.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Method Section
                const Text(
                  'Payment method',
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
                      Icon(Icons.apple, size: 24), // Placeholder for Apple Pay icon
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Apple Pay',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Orden Summary Section
                const Text(
                  'Orden summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Orden nr:'),
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
                _buildSummaryRow('2 × Broccoli Lorem Ipsum', '2,80 €'),
                _buildSummaryRow('1 × Carrots Lorem Ipsum', '1,60 €'),
                _buildSummaryRow('2 × Coca-Cola 0,30 L', '5,40 €'),
                _buildSummaryRow('2 × Eggplant text here', '2,20 €'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildSummaryRow('Payment method', 'Apple Pay', isBold: true),
                _buildSummaryRow('Delivery', '${deliveryFee.toStringAsFixed(2)} €'),
                _buildSummaryRow('Tip', '${tipAmount.toStringAsFixed(2)} €'),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total incl. VAT',
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
                      const TextSpan(text: 'By placing your order you agree to our '),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline),
                      ),
                      const TextSpan(text: ' and confirm that you have read our '),
                      TextSpan(
                        text: 'rights of Withdrawal',
                        style: TextStyle(
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline),
                      ),
                      const TextSpan(text: ' and our '),
                      TextSpan(
                        text: 'Policy',
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
                text: 'Confirm and Pay ${totalInclVAT.toStringAsFixed(2)} €',
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