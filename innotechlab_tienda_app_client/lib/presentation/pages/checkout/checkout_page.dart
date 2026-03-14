import 'package:flutter/material.dart';
import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/provider/cart_provider.dart';
import 'package:flutter_app/presentation/provider/checkout_provider.dart'
    show checkoutDeliveryFee, checkoutProvider;
import 'package:flutter_app/presentation/provider/home_provider.dart';
import 'package:flutter_app/presentation/provider/shop_status_provider.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class CheckoutPageModal extends ConsumerStatefulWidget {
  const CheckoutPageModal({super.key});

  @override
  ConsumerState<CheckoutPageModal> createState() => _CheckoutPageModalState();
}

class _CheckoutPageModalState extends ConsumerState<CheckoutPageModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final LocationService _locationService = LocationService();

  bool _callWhenArrive = false;
  bool _leaveAtDoor = true;
  bool _dontRingBell = false;

  LocationResult? _currentLocation;

  @override
  void initState() {
    super.initState();
    _addressController.text = 'Dirección de entrega';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      _currentLocation = await _locationService.getCurrentPosition(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );

      if (!mounted) return;

      _addressController.text =
          'Ubicación GPS (${_currentLocation!.latitude.toStringAsFixed(5)}, ${_currentLocation!.longitude.toStringAsFixed(5)})';

      showInfoToast(
        context,
        message:
            'Ubicación aplicada. Precisión: ${_locationService.getAccuracyDescription(_currentLocation!.accuracy)}',
        backgroundColor: AppColors.successColor,
        icon: Icons.my_location,
        isDismissible: true,
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      showInfoToast(
        context,
        message: e.message,
        backgroundColor: AppColors.errorColor,
        icon: Icons.location_off,
        isDismissible: true,
      );
    } catch (e) {
      if (!mounted) return;
      showInfoToast(
        context,
        message: 'Error al obtener ubicación',
        backgroundColor: AppColors.errorColor,
        icon: Icons.location_off,
        isDismissible: true,
      );
    }
  }

  Future<void> _confirmOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cartItems = ref.read(cartProvider).cartItems;
    final selectedShop = ref.read(homeProvider).selectedShop;

    if (selectedShop == null) {
      showInfoToast(
        context,
        message: 'Por favor selecciona una tienda',
        backgroundColor: AppColors.errorColor,
        icon: Icons.store,
        isDismissible: true,
      );
      return;
    }

    // Check shop status before proceeding
    final shopStatus = ref.read(shopStatusProvider(selectedShop.id));
    if (!shopStatus.canOrder) {
      String message =
          shopStatus.message ??
          'El comercio no acepta pedidos en este momento.';

      if (shopStatus.status == ShopStatus.waiting) {
        message =
            'Temporalmente en pausa por alta demanda. Puedes ver los productos pero no puedes realizar pedidos.';
      } else if (shopStatus.status == ShopStatus.closed) {
        message = shopStatus.nextOpenTime != null
            ? 'El comercio está cerrado. Próxima apertura: ${shopStatus.nextOpenTime}'
            : 'El comercio está cerrado en este momento.';
      } else if (shopStatus.status == ShopStatus.inactive) {
        message = 'El comercio no está disponible actualmente.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No disponible'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final shopId = selectedShop.id;

    // Sanitize inputs for security
    final sanitizedAddress = _addressController.text.trim();
    final sanitizedNotes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final success = await ref
        .read(checkoutProvider.notifier)
        .placeOrder(
          shopId: shopId,
          cartItems: cartItems,
          shippingAddress: sanitizedAddress,
          notes: sanitizedNotes,
          shippingLatitude: _currentLocation?.latitude,
          shippingLongitude: _currentLocation?.longitude,
        );

    if (!mounted) return;

    if (!success) {
      final error =
          ref.read(checkoutProvider).errorMessage ??
          'No se pudo crear la orden.';
      showInfoToast(
        context,
        message: error,
        backgroundColor: AppColors.errorColor,
        icon: Icons.error_outline,
        isDismissible: true,
      );
      return;
    }

    ref.read(cartProvider.notifier).clearCart();

    // Obtener el código de orden para mostrar en la confirmación
    final orderCode = ref.read(checkoutProvider).createdOrderCode;

    showInfoToast(
      context,
      message: orderCode != null
          ? 'Orden creada. Código: $orderCode'
          : 'Orden creada correctamente.',
      backgroundColor: AppColors.successColor,
      icon: Icons.check_circle_outline,
      isDismissible: true,
    );

    // Navegar a la página de confirmación para mostrar el código prominently
    context.go('/order-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);

    final subtotal = checkoutNotifier.subtotal(cartState.cartItems);
    final total = checkoutNotifier.total(cartState.cartItems);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Entrega',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _addressController,
                    hintText: 'Escribe tu dirección',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La dirección es obligatoria';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  color: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _notesController,
              hintText: 'Notas adicionales (opcional)',
              prefixIcon: Icons.note_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Llamar cuando llegue'),
              value: _callWhenArrive,
              onChanged: (value) {
                setState(() {
                  _callWhenArrive = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Dejar en la puerta'),
              value: _leaveAtDoor,
              onChanged: (value) {
                setState(() {
                  _leaveAtDoor = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('No tocar timbre'),
              value: _dontRingBell,
              onChanged: (value) {
                setState(() {
                  _dontRingBell = value;
                });
              },
            ),
            const Divider(height: 32),
            const Text(
              'Resumen del pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...cartState.cartItems.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text(
                  '${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                ),
                trailing: Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Envío'),
                Text('\$${checkoutDeliveryFee.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Confirmar pedido',
              onPressed: () {
                if (!checkoutState.isSubmitting) {
                  _confirmOrder();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
