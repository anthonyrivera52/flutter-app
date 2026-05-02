import 'package:flutter/material.dart';
import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/cart/domain/models/cart_item_entity.dart';
import 'package:flutter_app/features/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:flutter_app/features/orders/presentation/viewmodels/checkout_viewmodel.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_app/features/payments/presentation/widgets/payment_method_selector.dart';
import 'package:flutter_app/features/payments/presentation/widgets/bold_payment_sheet.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_app/presentation/widget/common/price_display.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/payments/payment_models.dart';
import '../../../../core/services/payments/bold_payment_service.dart';

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

  String? _userName;
  String? _userEmail;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() {
        _userName =
            user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email?.split('@').first ??
            'Cliente';
        _userEmail = user.email;
        _userPhone = user.userMetadata?['phone'] as String?;
      });

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone')
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse != null && mounted) {
        setState(() {
          _userName = profileResponse['full_name'] as String? ?? _userName;
          _userPhone = profileResponse['phone'] as String? ?? _userPhone;
        });
      }
    } catch (_) {}
  }

  BoldBuyerData? _buildBuyerData() {
    if (_userName == null || _userEmail == null) return null;

    return BoldBuyerData(
      name: _userName!,
      email: _userEmail!,
      phone: _userPhone,
    );
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('customer_addresses')
          .select()
          .eq('customer_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response != null && mounted) {
        final line1 = response['line1'] as String?;
        final lat = (response['lat'] as num?)?.toDouble();
        final lng = (response['lng'] as num?)?.toDouble();

        if (line1 != null && line1.isNotEmpty) {
          _addressController.text = line1;
        }
        if (lat != null && lng != null) {
          _currentLocation = LocationResult(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (_) {}
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

    final checkoutState = ref.read(checkoutProvider);

    if (checkoutState.selectedPaymentMethod == PaymentMethodType.cash) {
      _onCashPaymentSuccess();
    } else {
      await _processBoldPayment(cartItems);
    }
  }

  Future<void> _processBoldPayment(List<CartItem> cartItems) async {
    final buyerData = _buildBuyerData();

    final checkoutData = await ref
        .read(checkoutProvider.notifier)
        .prepareBoldCheckout(cartItems: cartItems, buyer: buyerData);

    if (!mounted) return;

    if (checkoutData == null) {
      final error =
          ref.read(checkoutProvider).paymentError ??
          'Error al preparar el pago';
      _showPaymentErrorDialog(error);
      return;
    }

    final result = await showBoldPaymentSheet(
      context: context,
      checkoutData: checkoutData,
    );

    if (!mounted) return;

    if (result == null || !result.success) {
      ref
          .read(checkoutProvider.notifier)
          .onBoldPaymentCompleted(
            success: false,
            error: result?.error ?? 'Pago cancelado',
          );
      _showPaymentErrorDialog(result?.error ?? 'El pago no fue completado');
      return;
    }

    ref.read(checkoutProvider.notifier).onBoldPaymentCompleted(success: true);
    _onCashPaymentSuccess();
  }

  void _onCashPaymentSuccess() {
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

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);

    final subtotal = checkoutState.subtotal(cartState.items);
    final grandTotal = checkoutState.grandTotal(cartState.items);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
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

                  _buildSectionTitle('Propina para el repartidor'),
                  _buildTipSelector(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Resumen del pedido'),
                  _buildOrderSummary(cartState.items),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Método de pago'),
                  _buildPaymentSection(checkoutState),
                  const SizedBox(height: 24),

                  _buildPaymentSummary(subtotal, grandTotal),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Pagar',
                    isLoading:
                        checkoutState.isSubmitting ||
                        checkoutState.isPaymentProcessing,
                    onPressed: _confirmOrder,
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

  void _onPlaceSelected(String placeId, String description) async {
    FocusScope.of(context).unfocus();
    _addressController.text = description;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'get-place-details',
        body: {'placeId': placeId},
      );
      if (response.data != null && mounted) {
        final lat = response.data['lat'] as double?;
        final lng = response.data['lng'] as double?;
        if (lat != null && lng != null) {
          _currentLocation = LocationResult(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      // Silently fail - address still saved
    }
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
                  hintText: 'Ingresa tu dirección...',
                  prefixIcon: Icons.location_on_rounded,
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

  Widget _buildTipSelector() {
    final checkoutState = ref.watch(checkoutProvider);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cuánto quieres dar de propina?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: kTipOptions.map((tip) {
              final isSelected = checkoutState.selectedTip == tip;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      ref.read(checkoutProvider.notifier).selectTip(tip);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '\$$tip',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(CheckoutState checkoutState) {
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
      child: PaymentMethodSelector(
        selectedMethod: checkoutState.selectedPaymentMethod,
        onMethodSelected: (method) {
          ref.read(checkoutProvider.notifier).selectPaymentMethod(method);
        },
        isProcessing: checkoutState.isPaymentProcessing,
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
                    PriceText(
                      price: item.price * item.quantity,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPaymentSummary(double subtotal, double grandTotal) {
    final checkoutState = ref.watch(checkoutProvider);
    final ivaAmount = checkoutState.ivaAmount(ref.read(cartProvider).items);
    final commerceFee = checkoutState.commerceFeeAmount;
    final commerceFeeLabel = checkoutState.commerceFeeLabel;

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
            child: PriceText(price: subtotal),
          ),
          const SizedBox(height: 8),
          _RowSummary(
            label: 'IVA (${checkoutState.ivaPercentage.toStringAsFixed(0)}%)',
            child: PriceText(price: ivaAmount),
          ),
          const SizedBox(height: 8),
          _RowSummary(
            label: commerceFeeLabel,
            child: PriceText(price: commerceFee),
          ),
          const SizedBox(height: 8),
          _RowSummary(
            label: 'Tarifa de envío',
            child: PriceText(price: kDeliveryFee),
          ),
          const SizedBox(height: 8),
          _RowSummary(
            label: 'Propina',
            child: PriceText(price: checkoutState.selectedTip),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a Pagar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              PriceText(
                price: grandTotal,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryColor,
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
  final Widget child;
  const _RowSummary({required this.label, required this.child});

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
        child,
      ],
    );
  }
}
