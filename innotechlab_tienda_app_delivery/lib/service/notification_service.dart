import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart'; // Para GlobalKey<NavigatorState>

// GlobalKey para navegar desde fuera del contexto de un widget
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream para manejar las respuestas de las notificaciones (cuando se tocan)
  // en cualquier estado de la app (foreground, background, terminated)
  final BehaviorSubject<String?> onNotifications = BehaviorSubject<String?>();

  Future<void> init() async {
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // 'app_icon' es el nombre de tu icono en drawable

    // Configuración para iOS
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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Este callback se dispara cuando se toca una notificación en primer plano,
        // o si la app se abre desde el background/terminated al tocar la notificación.
        if (response.payload != null) {
          debugPrint('notification payload: ${response.payload}');
          onNotifications.add(response.payload); // Envía el payload al stream
        }
      },
      // Este es el manejador para cuando la app está en segundo plano o terminada
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    // Solicitar permisos de notificación en iOS (es una buena práctica)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Define los detalles de la notificación
  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_order_channel_id', // ID único del canal
      'Nuevos Pedidos', // Nombre del canal (visible en la configuración de Android)
      channelDescription: 'Notificaciones para nuevos pedidos de delivery', // Descripción
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker', // Texto que aparece brevemente en la barra de estado
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
  }

  // Muestra una notificación local
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
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
// Debe ser una función top-level para que el sistema operativo la pueda invocar.
@pragma('vm:entry-point') // Anotación necesaria para JIT en dispositivos Android
void _onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
  debugPrint('Background notification tapped with payload: ${notificationResponse.payload}');
  if (notificationResponse.payload != null) {
    // Usamos el GlobalKey para navegar
    navigatorKey.currentState?.pushNamed(notificationResponse.payload!);
  }
}