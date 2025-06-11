
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importa go_router para la navegación

/// Página de inicio simple para demostrar la navegación con router.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final notificationState = ref.watch(notificationProvider);
//     final notificationNotifier = ref.read(notificationProvider.notifier);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notificaciones y Ofertas'),
//       ),
//       body: notificationState.notifications.isEmpty
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.notifications_off, size: 80, color: Colors.grey),
//                   SizedBox(height: 20),
//                   Text(
//                     'No tienes notificaciones por ahora.',
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(16.0),
//               itemCount: notificationState.notifications.length,
//               itemBuilder: (context, index) {
//                 final notification = notificationState.notifications[index];
//                 return NotificationCard(
//                  // notification: notification,
//                   onTap: () {
//                     notificationNotifier.markAsRead(notification.id);
//                     // Handle navigation based on notification data (e.g., to product page, offer page)
//                     if (notification.data['type'] == 'offer' && notification.data.containsKey('offer_id')) {
//                       // context.go('/offers/${notification.data['offer_id']}');
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Abriendo oferta: ${notification.data['offer_id']} (simulado)')),
//                       );
//                     }
//                   },
//                   title: '',
//                   body: '',
//                   timestamp: notification.timestamp,
//                 );
//               },
//             ),
//     );
//   }
// }