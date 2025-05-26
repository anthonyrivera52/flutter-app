
// presentation/pages/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/presentation/providers/notification_provider.dart';
import 'package:mi_tienda/presentation/widgets/notification_card.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notificationNotifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones y Ofertas'),
      ),
      body: notificationState.notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No tienes notificaciones por ahora.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notificationState.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationState.notifications[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () {
                    notificationNotifier.markAsRead(notification.id);
                    // Handle navigation based on notification data (e.g., to product page, offer page)
                    if (notification.data['type'] == 'offer' && notification.data.containsKey('offer_id')) {
                      // context.go('/offers/${notification.data['offer_id']}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Abriendo oferta: ${notification.data['offer_id']} (simulado)')),
                      );
                    }
                  }, title: '', body: '', timestamp: null,
                );
              },
            ),
    );
  }
}
