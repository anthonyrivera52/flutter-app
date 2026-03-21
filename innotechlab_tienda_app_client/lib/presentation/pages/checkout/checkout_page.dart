import 'package:flutter/material.dart';
import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:flutter_app/features/orders/presentation/viewmodels/checkout_viewmodel.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_app/features/payments/presentation/widgets/card_input_form.dart';
import 'package:flutter_app/features/payments/presentation/widgets/payment_method_selector.dart';
import 'package:flutter_app/presentation/provider/shop_status_provider.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/payments/payment_models.dart';

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
  CardData? _pendingCardData;

  @override
  void initState() {
    super.initState();
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
        message: 'Ubicación aplicada con éxito.',
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

    final cartItems = ref.read(cartProvider).items;
    final selectedShop = ref.read(homeProvider).selectedShop;
    final checkoutState = ref.read(checkoutProvider);

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

    final shopStatus = ref.read(shopStatusProvider(selectedShop.id));
    if (!shopStatus.canOrder) {
      String message =
          shopStatus.message ??
          'El comercio no acepta pedidos en este momento.';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Comercio no disponible'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final sanitizedAddress = _addressController.text.trim();
    final sanitizedNotes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final orderSuccess = await ref
        .read(checkoutProvider.notifier)
        .placeOrder(
          shopId: selectedShop.id,
          cartItems: cartItems,
          shippingAddress: sanitizedAddress,
          notes: sanitizedNotes,
          shippingLatitude: _currentLocation?.latitude,
          shippingLongitude: _currentLocation?.longitude,
        );

    if (!mounted) return;

    if (!orderSuccess) {
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

    final orderId = ref.read(checkoutProvider).createdOrderId;
    if (orderId == null) {
      showInfoToast(
        context,
        message: 'Error al procesar la orden',
        backgroundColor: AppColors.errorColor,
        icon: Icons.error_outline,
        isDismissible: true,
      );
      return;
    }

    final total = checkoutState.total(cartItems);

    final paymentSuccess = await ref
        .read(checkoutProvider.notifier)
        .processPayment(
          saleId: orderId,
          cardData: _pendingCardData,
          amount: total,
        );

    if (!mounted) return;

    if (!paymentSuccess) {
      final paymentError = ref.read(checkoutProvider).paymentError;
      _showPaymentErrorDialog(paymentError ?? 'Error al procesar el pago');
      return;
    }

    ref.read(cartProvider.notifier).clear();
    ref.read(checkoutProvider.notifier).reset();

    context.go('/order-confirmation');
  }

  void _showPaymentErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pago fallido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (ref.read(checkoutProvider).selectedPaymentMethod ==
              PaymentMethodType.card)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(checkoutProvider.notifier).switchToCash();
              },
              child: const Text('Pagar en efectivo'),
            ),
        ],
      ),
    );
  }

  void _onCardSubmit(CardData cardData) {
    setState(() {
      _pendingCardData = cardData;
    });
    _confirmOrder();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);

    final subtotal = checkoutState.subtotal(cartState.items);
    final total = checkoutState.total(cartState.items);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Finalizar Pedido',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  _buildSectionTitle('Ubicación de entrega'),
                  _buildDeliverySection(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Instrucciones de entrega'),
                  _buildOptionsSection(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Resumen del pedido'),
                  _buildOrderSummary(cartState.items),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Método de pago'),
                  _buildPaymentSection(checkoutState, total),
                  const SizedBox(height: 24),

                  _buildPaymentSummary(subtotal, total),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Confirmar y Pagar',
                    isLoading:
                        checkoutState.isSubmitting ||
                        checkoutState.isPaymentProcessing,
                    onPressed: () {
                      if (checkoutState.selectedPaymentMethod ==
                          PaymentMethodType.card) {
                        _showCardFormDialog();
                      } else {
                        _confirmOrder();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _addressController,
                  hintText: 'Ej: Calle Principal 123',
                  prefixIcon: Icons.location_on_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu dirección';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _useCurrentLocation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _notesController,
            hintText: 'Apartamento, piso, oficina o referencias...',
            prefixIcon: Icons.notes_rounded,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionTile(
            title: 'Llamar al llegar',
            subtitle: 'El repartidor te llamará por teléfono',
            icon: Icons.phone_in_talk_rounded,
            value: _callWhenArrive,
            onChanged: (v) => setState(() => _callWhenArrive = v),
          ),
          const Divider(height: 1, indent: 60),
          _buildOptionTile(
            title: 'Dejar en la puerta',
            subtitle: 'Entrega sin contacto personal',
            icon: Icons.door_front_door_rounded,
            value: _leaveAtDoor,
            onChanged: (v) => setState(() => _leaveAtDoor = v),
          ),
          const Divider(height: 1, indent: 60),
          _buildOptionTile(
            title: 'No tocar el timbre',
            subtitle: 'Ideal si tienes bebés o mascotas',
            icon: Icons.notifications_off_rounded,
            value: _dontRingBell,
            onChanged: (v) => setState(() => _dontRingBell = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(CheckoutState checkoutState, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentMethodSelector(
            selectedMethod: checkoutState.selectedPaymentMethod,
            onMethodSelected: (method) {
              ref.read(checkoutProvider.notifier).selectPaymentMethod(method);
            },
            isProcessing: checkoutState.isPaymentProcessing,
          ),
          if (checkoutState.selectedPaymentMethod ==
              PaymentMethodType.card) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ingresa los datos de tu tarjeta al confirmar',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCardFormDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Datos de Tarjeta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: CardInputForm(
                onSubmit: (cardData) {
                  Navigator.pop(ctx);
                  _onCardSubmit(cardData);
                },
                isProcessing: ref.read(checkoutProvider).isPaymentProcessing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      activeTrackColor: AppColors.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildOrderSummary(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}x',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPaymentSummary(double subtotal, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _RowSummary(
            label: 'Subtotal',
            value: '\$${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _RowSummary(
            label: 'Tarifa de envío',
            value: '\$${kDeliveryFee.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Final',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowSummary extends StatelessWidget {
  final String label;
  final String value;
  const _RowSummary({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }
}
