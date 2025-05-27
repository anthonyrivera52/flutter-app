import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/presentation/providers/notification_provider.dart';
import 'package:mi_tienda/presentation/widgets/notification_card.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsyncValue = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: notificationsAsyncValue.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('No tienes notificaciones.', style: TextStyle(fontSize: 16, color: AppColors.textLightColor)),
            );
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                title: notification.title,
                body: notification.body,
                timestamp: notification.timestamp,
                onTap: () {
                  // Aquí puedes añadir lógica para navegar a una pantalla específica
                  // o marcar la notificación como leída
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notificación "${notification.title}" tocada.')),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar notificaciones: $error')),
      ),
    );
  }
}
