import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/core/errors/failures.dart'; // Asegúrate de que tu Failure tenga ServerFailure
import 'package:mi_tienda/service_locator.dart'; // Para acceder a SupabaseClient

// Entidad de notificación (si no existe, crea una en domain/entities/notification.dart)
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data; // Datos adicionales, como order_id

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
  });

  // Método para crear una notificación desde un payload de pg_notify
  factory AppNotification.fromSupabaseRealtimePayload(Map<String, dynamic> payload) {
    // El payload de pg_notify viene en `payload['payload']` como String JSON
    final String rawData = payload['payload'] as String;
    final Map<String, dynamic> customData = jsonDecode(rawData);

    // Puedes personalizar el título y cuerpo de la notificación
    String title = 'Nueva Orden Confirmada';
    String body = 'Orden #${(customData['order_id'] as String).substring(0, 8)} - Total: \$${(customData['total_amount'] as num).toStringAsFixed(2)}';

    return AppNotification(
      id: customData['order_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), // Usa order_id como ID
      title: title,
      body: body,
      timestamp: DateTime.parse(customData['created_at'] ?? DateTime.now().toIso8601String()),
      data: customData,
    );
  }
}

// Estado del provider de notificaciones
final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  return NotificationNotifier(supabaseClient);
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final SupabaseClient _supabaseClient;
  late final RealtimeChannel _orderConfirmationChannel; // Canal para órdenes confirmadas

  NotificationNotifier(this._supabaseClient) : super(const AsyncValue.loading()) {
    _initNotifications();
  }

  void _initNotifications() async {
    // Aquí puedes cargar notificaciones históricas si las guardas en algún lugar (ej. base de datos local)
    // Por ahora, iniciamos con una lista vacía y escuchamos nuevas.
    state = const AsyncValue.data([]);

    // Suscribirse al canal de notificaciones de órdenes confirmadas
    _orderConfirmationChannel = _supabaseClient.channel('public:new_delivery_order');

    _orderConfirmationChannel.on(
      RealtimeListenType.postgresChanges,
      ChannelFilter(
        event: 'NEW_DELIVERY_ORDER', // Este es el evento de pg_notify
        schema: 'public',
        // No es necesario especificar 'table' si se usa pg_notify y se filtra por 'event' (nombre del canal)
      ),
      (payload, [ref]) {
        try {
          final newNotification = AppNotification.fromSupabaseRealtimePayload(payload);
          // Añadir la nueva notificación al inicio de la lista
          state = AsyncValue.data([newNotification, ...state.value ?? []]);
          print('✅ Nueva notificación recibida: ${newNotification.title}');
        } catch (e, st) {
          // Manejar errores al procesar el payload
          print('Error al procesar notificación de Supabase Realtime: $e\n$st');
        }
      },
    ).subscribe();

    // Puedes simular alguna notificación inicial o cargarlas desde un almacenamiento persistente
    _simulateInitialNotifications();
  }

  void _simulateInitialNotifications() {
    // Solo para fines de demostración
    final dummyNotifications = [
      AppNotification(
        id: '1',
        title: '¡Bienvenido!',
        body: 'Gracias por usar Mi Tienda. ¡Explora nuestros productos!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      AppNotification(
        id: '2',
        title: 'Oferta Especial',
        body: '¡No te pierdas el 20% de descuento en todos los electrónicos!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
    state = AsyncValue.data([...state.value ?? [], ...dummyNotifications]);
  }

  // Puedes añadir métodos para marcar como leídas, eliminar, etc.
  void markNotificationAsRead(String id) {
    state = AsyncValue.data(
      state.value!.map((n) => n.id == id ? n : n).toList(), // Ejemplo, si tu AppNotification tuviera un campo 'isRead'
    );
  }

  void removeNotification(String id) {
    state = AsyncValue.data(
      state.value!.where((n) => n.id != id).toList(),
    );
  }

  @override
  void dispose() {
    _supabaseClient.removeChannel(_orderConfirmationChannel);
    super.dispose();
  }
}

// **IMPORTANTE**: Define la entidad AppNotification si no la tienes
// lib/domain/entities/notification.dart
/*
import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
  });

  @override
  List<Object?> get props => [id, title, body, timestamp, data];
}
*/