import 'dart:async';

import 'package:delivery_app_mvvm/model/order.dart';
import 'package:flutter/material.dart';

class NewOrderAlertWidget extends StatefulWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const NewOrderAlertWidget({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  _NewOrderAlertWidgetState createState() => _NewOrderAlertWidgetState();
}

class _NewOrderAlertWidgetState extends State<NewOrderAlertWidget> {
  static const int _countdownDurationSeconds = 10; // Duración del temporizador en segundos
  late double _currentProgress;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentProgress = 1.0; // Inicia la barra de progreso en 100%
    _startCountdown();
  }

  void _startCountdown() {
    int remainingSeconds = _countdownDurationSeconds;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) { // Asegura que el widget sigue montado
        timer.cancel();
        return;
      }

      setState(() {
        _currentProgress = timer.tick / (_countdownDurationSeconds * 10); // tick es en 100ms
        // Queremos que el progreso vaya de 1.0 a 0.0
        _currentProgress = 1.0 - _currentProgress;
      });

      if (timer.tick >= (_countdownDurationSeconds * 10)) {
        timer.cancel();
        // Si el tiempo se acaba, automáticamente declina la orden
        widget.onDecline();
      }
    });
  }

  void _cancelTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  @override
  void dispose() {
    _cancelTimer(); // Asegúrate de cancelar el temporizador al desechar el widget
    super.dispose();
  }

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
            const Row(
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
            const SizedBox(height: 15),
            // Barra de progreso lineal
            LinearProgressIndicator(
              value: _currentProgress, // El progreso va de 1.0 a 0.0
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                // Cambia de color a medida que el tiempo se agota
                _currentProgress > 0.5
                    ? Colors.green
                    : _currentProgress > 0.2
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            Text(
              'Cliente: ${widget.order.customerName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Dirección: ${widget.order.customerAddress}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${widget.order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Ganancias Estimadas: \$${widget.order.estimatedEarnings.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.blue[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Distancia: ${widget.order.distanceKm.toStringAsFixed(1)} km',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _cancelTimer(); // Cancela el temporizador al aceptar
                      widget.onAccept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Color de fondo
                      foregroundColor: Colors.white, // Color del texto
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _cancelTimer(); // Cancela el temporizador al declinar
                      widget.onDecline();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, // Color del texto
                      side: const BorderSide(color: Colors.red), // Color del borde
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
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