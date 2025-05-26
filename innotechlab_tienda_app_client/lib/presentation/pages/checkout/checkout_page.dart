// presentation/pages/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:mi_tienda/core/utils/from_validator.dart';
import 'package:mi_tienda/presentation/providers/checkout_provider.dart';
import 'package:mi_tienda/presentation/providers/cart_provider.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_button.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_text_field.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  double? _userLatitude;
  double? _userLongitude;
  bool _isLocating = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, handle the case
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado. No se puede obtener la ubicación.')),
          );
          setState(() {
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado permanentemente. Habilita desde la configuración.')),
        );
        setState(() {
          _isLocating = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _addressController.text = 'Lat: ${_userLatitude!.toStringAsFixed(4)}, Lon: ${_userLongitude!.toStringAsFixed(4)} (Ubicación GPS)';
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
        _isLocating = false;
      });
    }
  }

  void _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_userLatitude == null || _userLongitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, obtén tu ubicación o ingresa una dirección completa.')),
        );
        return;
      }

      final checkoutNotifier = ref.read(checkoutProvider.notifier);
      final cartItems = ref.read(cartProvider).cartItems;
      final totalAmount = ref.read(cartProvider).totalAmount;

      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El carrito está vacío. Agrega productos antes de pagar.')),
        );
        return;
      }

      final success = await checkoutNotifier.placeOrder(
        cartItems: cartItems,
        totalAmount: totalAmount,
        shippingAddress: _addressController.text.trim(),
        shippingLatitude: _userLatitude!,
        shippingLongitude: _userLongitude!,
        notes: _notesController.text.trim(),
      );

      if (success) {
        ref.read(cartProvider.notifier).clearCart(); // Clear cart after successful order
        context.go('/order-confirmation', extra: {
          'userLatitude': _userLatitude,
          'userLongitude': _userLongitude,
        }); // Pass data to order confirmation
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(checkoutNotifier.errorMessage ?? 'Error al procesar el pago'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final cartState = ref.watch(cartProvider); // To display total amount

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen del Pedido',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Display Cart Items (summary)
              ...cartState.cartItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item.quantity} x ${item.product.name}', overflow: TextOverflow.ellipsis),
                        ),
                        Text('\$${(item.quantity * item.product.price).toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                  ),
                  Text(
                    '\$${cartState.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Información de Envío',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _addressController,
                labelText: 'Dirección de Envío',
                validator: (value) => FormValidators.isValidateEmpty(value),
                suffixIcon: _isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                      ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _notesController,
                labelText: 'Notas para la Entrega (opcional)',
              ),
              const SizedBox(height: 30),
              checkoutState.isLoading
                  ? const LoadingIndicator()
                  : CustomButton(
                      text: 'Confirmar Pedido y Pagar',
                      onPressed: _placeOrder,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// // checkout_provider.dart (ViewModel)
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mi_tienda/domain/entities/cart_item.dart';
// import 'package:mi_tienda/domain/usecases/order/place_order_usecase.dart';
// import 'package:mi_tienda/core/errors/failures.dart';

// class CheckoutState {
//   final bool isLoading;
//   final String? errorMessage;
//   final String? successMessage;

//   CheckoutState({this.isLoading = false, this.errorMessage, this.successMessage});

//   CheckoutState copyWith({
//     bool? isLoading,
//     String? errorMessage,
//     String? successMessage,
//   }) {
//     return CheckoutState(
//       isLoading: isLoading ?? this.isLoading,
//       errorMessage: errorMessage,
//       successMessage: successMessage,
//     );
//   }
// }

// final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
//   return CheckoutNotifier(
//     placeOrderUseCase: ref.read(placeOrderUseCaseProvider),
//   );
// });

// class CheckoutNotifier extends StateNotifier<CheckoutState> {
//   final PlaceOrderUseCase placeOrderUseCase;

//   CheckoutNotifier({required this.placeOrderUseCase}) : super(CheckoutState());

//   Future<bool> placeOrder({
//     required List<CartItem> cartItems,
//     required double totalAmount,
//     required String shippingAddress,
//     required double shippingLatitude,
//     required double shippingLongitude,
//     String? notes,
//   }) async {
//     state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

//     final result = await placeOrderUseCase(PlaceOrderParams(
//       cartItems: cartItems,
//       totalAmount: totalAmount,
//       shippingAddress: shippingAddress,
//       shippingLatitude: shippingLatitude,
//       shippingLongitude: shippingLongitude,
//       notes: notes,
//     ));

//     return result.fold(
//       (failure) {
//         state = state.copyWith(isLoading: false, errorMessage: failure.message);
//         return false;
//       },
//       (_) {
//         state = state.copyWith(isLoading: false, successMessage: 'Pedido realizado con éxito!');
//         return true;
//       },
//     );
//   }
// }
