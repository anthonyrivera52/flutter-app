// Add this new widget as a private class inside _HomeScreenState or in a separate file
// (e.g., widgets/order_action_buttons_carousel.dart) if you prefer.
// For simplicity, I'm including it directly in the HomeScreenState for this example.

import 'package:delivery_app_mvvm/model/order.dart';
import 'package:delivery_app_mvvm/viewmodel/active_order_viewmodel.dart';
import 'package:flutter/material.dart';

class OrderActionButtonsCarousel extends StatelessWidget {
  final ActiveOrderViewModel viewModel;
  final Function(String) onMakePhoneCall;
  final Function(String) onOpenChat;
  final Function(BuildContext, Order, ActiveOrderViewModel) onShowPickupItemsModal;
  final Function(BuildContext, Order) onShowPickupCodeModal;
  final Function(BuildContext, Order) onShowDeliveryCodeModal;
  final Function(String) onShowSnackBar;
  final String Function(String) getActionButtonText;
  final String? Function(String) getNextStatus;


  const OrderActionButtonsCarousel({
    super.key,
    required this.viewModel,
    required this.onMakePhoneCall,
    required this.onOpenChat,
    required this.onShowPickupItemsModal,
    required this.onShowPickupCodeModal,
    required this.onShowDeliveryCodeModal,
    required this.onShowSnackBar,
    required this.getActionButtonText,
    required this.getNextStatus,
  });

  @override
  Widget build(BuildContext context) {
    final order = viewModel.activeOrder!;
    final bool hasItemsToPickUp = order.items != null && order.items!.isNotEmpty;

    List<Widget> actionButtons = [];

    // 1. Call Button
    actionButtons.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: () => onMakePhoneCall(order.customerPhone),
          icon: const Icon(Icons.call, color: Colors.white),
          label: const Text('Llamar', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );

    // 2. Chat Button
    actionButtons.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: () => onOpenChat(order.customerPhone),
          icon: const Icon(Icons.chat, color: Colors.white),
          label: const Text('Chatear', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );

    // 3. View Items Button (Conditional)
    if (hasItemsToPickUp && (order.status == 'arrived_at_restaurant' || order.status == 'picking_up')) {
      actionButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.list_alt, color: Colors.deepPurple),
            label: const Text('Ver Artículos', style: TextStyle(color: Colors.deepPurple)),
            onPressed: () => onShowPickupItemsModal(context, order, viewModel),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.deepPurple),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
      );
    }

    // 4. Main Action Button (Next Step)
    actionButtons.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: viewModel.isLoading
              ? null
              : () async {
                  String? nextStatus = getNextStatus(order.status);

                  if (nextStatus == 'arrived_at_restaurant') {
                    // Update status BEFORE showing modal
                    await viewModel.updateOrderStatus(nextStatus!);
                    onShowPickupCodeModal(context, order);
                  } else if (nextStatus == 'picked_up') {
                    // Check if all items are checked if applicable
                    if (hasItemsToPickUp && viewModel.itemChecked.contains(false)) {
                      onShowSnackBar('Por favor, marca todos los artículos como recogidos.');
                      onShowPickupItemsModal(context, order, viewModel); // Re-open modal
                      return;
                    }
                    await viewModel.updateOrderStatus(nextStatus!);
                    onShowSnackBar('¡Pedido recogido! En camino al cliente.');
                  } else if (nextStatus == 'delivered') {
                    // Show delivery code modal, update happens inside modal
                    onShowDeliveryCodeModal(context, order);
                  } else if (nextStatus != null) {
                    await viewModel.updateOrderStatus(nextStatus);
                    onShowSnackBar('Estado actualizado a: $nextStatus');
                  } else {
                    onShowSnackBar('No hay un siguiente estado definido o la acción no es válida.');
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          child: viewModel.isLoading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text(
                  getActionButtonText(order.status),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
      ),
    );

    // 5. Cancel Order Button (Debug/Conditional)
    if (viewModel.activeOrder != null && viewModel.activeOrder!.status != 'delivered') {
      actionButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: OutlinedButton(
            onPressed: () {
              viewModel.clearActiveOrder('rejected');
              onShowSnackBar('Orden activa cancelada/limpiada (Debug).');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: const Text('Cancelar (Debug)'),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align buttons to the start
          children: actionButtons,
        ),
      ),
    );
  }
}