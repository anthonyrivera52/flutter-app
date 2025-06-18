import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart'; // Para BehaviorSubject
import 'package:flutter/material.dart'; // Para GlobalKey<NavigatorState> y debugPrint

// GlobalKey para navegar desde fuera del contexto de un widget
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream para manejar las respuestas de las notificaciones (cuando se tocan)
  // en cualquier estado de la app (foreground, background, terminated)
  final BehaviorSubject<String?> onNotifications = BehaviorSubject<String?>();

  Future<void> init() async {
    // Configuración para Android: especifica el nombre del icono en la carpeta mipmap
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Asegúrate que 'app_icon' exista en mipmap

    // Configuración para iOS: solicita permisos al usuario
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Inicializar el plugin de notificaciones
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Manejador para cuando la notificación es tocada y la app está en primer plano
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          debugPrint('Notification payload (foreground/tap): ${response.payload}');
          onNotifications.add(response.payload); // Envía el payload al stream
        }
      },
      // Manejador para cuando la notificación es tocada y la app está en segundo plano o terminada
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    // Solicitar permisos de notificación explícitamente en iOS (buena práctica)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Define los detalles de la notificación (cómo se verá en Android e iOS)
  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_order_channel_id', // ID único del canal (requerido para Android O+)
      'Nuevos Pedidos', // Nombre del canal (visible en la configuración de notificaciones de Android)
      channelDescription: 'Notificaciones para nuevos pedidos de la tienda', // Descripción del canal
      importance: Importance.max, // Nivel de importancia (HIGH)
      priority: Priority.high,    // Prioridad (HIGH)
      ticker: 'Nuevo Pedido!',    // Texto que aparece brevemente en la barra de estado
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,  // Mostrar alerta
      presentBadge: true,  // Actualizar badge
      presentSound: true,  // Reproducir sonido
    );
    return const NotificationDetails(
      // android: androidPlatformChannelChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
  }

  // Muestra una notificación local
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload, // Datos que se pasan al tocar la notificación (ej. ID de la orden)
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }
}

// Función top-level para manejar las notificaciones cuando la app está en segundo plano o terminada
// Debe ser una función top-level (fuera de cualquier clase) para que el sistema operativo la pueda invocar.
@pragma('vm:entry-point') // Anotación necesaria para el JIT de Dart en dispositivos Android
void _onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
  debugPrint('Background notification tapped with payload: ${notificationResponse.payload}');
  if (notificationResponse.payload != null) {
    // Usamos el GlobalKey para navegar a la ruta especificada en el payload
    // Esto asegura que la navegación funcione incluso si el widget que escuchaba
    // no está en el árbol de widgets activo.
    navigatorKey.currentState?.pushNamed(notificationResponse.payload!);
  }
}