import 'package:flutter/material.dart';

class EarningDetailPage extends StatelessWidget {
  const EarningDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de ganancias")),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Aquí se muestra un desglose detallado de las ganancias por pedido, tipo de envío, comisiones, etc."),
      ),
    );
  }
}
