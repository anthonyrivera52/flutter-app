import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/app_notification.dart'; // Importa la entidad de notificación
import 'package:mi_tienda/domain/usecases/notifications/get_notifications_usecase.dart';
import 'package:mi_tienda/domain/usecases/notifications/add_notification_usecase.dart';
import 'package:mi_tienda/service_locator.dart';

// Proveedor de notificaciones
final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  final getNotificationsUseCase = ref.read(getNotificationsUseCaseProvider);
  final addNotificationUseCase = ref.read(addNotificationUseCaseProvider);
  return NotificationNotifier(
    supabaseClient,
    getNotificationsUseCase,
    addNotificationUseCase,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final SupabaseClient _supabaseClient;
  final GetNotificationsUseCase _getNotificationsUseCase;
  final AddNotificationUseCase _addNotificationUseCase;
  late final RealtimeChannel _orderConfirmationChannel;

  NotificationNotifier(
    this._supabaseClient,
    this._getNotificationsUseCase,
    this._addNotificationUseCase,
  ) : super(const AsyncValue.loading()) {
    _initNotifications();
  }

  void _initNotifications() async {
    // Cargar notificaciones históricas
    final result = await _getNotificationsUseCase(const NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(_mapFailureToMessage(failure), StackTrace.current),
      (notifications) => state = AsyncValue.data(notifications),
    );

    // Suscribirse al canal de notificaciones de órdenes confirmadas
    _orderConfirmationChannel = _supabaseClient.channel('public:new_delivery_order');

    _orderConfirmationChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'delivery_order', // Ajusta el nombre de la tabla si es diferente
      callback: (payload) async {
        try {
          final newNotification = AppNotification.fromSupabaseRealtimePayload(payload as Map<String, dynamic>);
          // Añadir la nueva notificación a la lista y guardarla localmente
          final currentNotifications = state.value ?? [];
          await _addNotificationUseCase(AddNotificationParams(newNotification));
          state = AsyncValue.data([newNotification, ...currentNotifications]);
          print('✅ Nueva notificación de orden recibida: ${newNotification.title}');
        } catch (e, st) {
          print('Error al procesar notificación de Supabase Realtime: $e\n$st');
        }
      },
    ).subscribe();
  }

  // Puedes añadir métodos para marcar como leídas, eliminar, etc.
  void markNotificationAsRead(String id) {
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
      // También podrías persistir este cambio si la notificación tiene un estado 'leído'
    }
  }

  void removeNotification(String id) async {
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.where((n) => n.id != id).toList(),
      );
      // Lógica para eliminar la notificación del almacenamiento local si es necesario
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return failure.message;
    } else {
      return 'Ocurrió un error inesperado.';
    }
  }

  @override
  void dispose() {
    _supabaseClient.removeChannel(_orderConfirmationChannel);
    super.dispose();
  }
}
