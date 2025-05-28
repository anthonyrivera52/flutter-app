import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importa go_router para la navegación

/// Página de detalles simple a la que se navega desde la página de inicio.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de Detalles'),
        backgroundColor: Colors.orangeAccent, // Color para diferenciar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¡Estás en la Página de Detalles!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navega de vuelta a la página de inicio
                context.goNamed('home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Color del botón
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Volver a Inicio',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
