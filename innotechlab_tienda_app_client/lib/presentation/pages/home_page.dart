import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importa go_router para la navegación

/// Página de inicio simple para demostrar la navegación con router.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de Inicio (Router)'),
        backgroundColor: Colors.blueAccent, // Color para diferenciar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¡Bienvenido a la Página de Inicio!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navega a la página de detalles usando el nombre de la ruta
                context.goNamed('detail');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Color del botón
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ir a Página de Detalles',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
