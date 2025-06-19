// lib/widgets/new_order_alert_widget.dart

import 'package:delivery_app_mvvm/model/order.dart';
import 'package:flutter/material.dart';

class NewOrderAlertWidget extends StatelessWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const NewOrderAlertWidget({
    Key? key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      // margin: EdgeInsets.zero, // Puedes quitar el margen si el Padding del Stack ya lo controla
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 8.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Toma el mínimo espacio vertical necesario
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange, size: 30),
                SizedBox(width: 10),
                Text(
                  '¡Nuevo Pedido!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Spacer(),
                // Aquí podrías añadir un ícono de reloj con el tiempo restante para aceptar
              ],
            ),
            Divider(height: 20, thickness: 1),
            Text(
              'Cliente: ${order.customerName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Dirección: ${order.customerAddress}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Ganancias Estimadas: \$${order.estimatedEarnings.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.blue[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Distancia: ${order.distanceKm.toStringAsFixed(1)} km',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Color de fondo
                      foregroundColor: Colors.white, // Color del texto
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Aceptar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, // Color del texto
                      side: BorderSide(color: Colors.red), // Color del borde
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Declinar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}