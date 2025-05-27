import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/domain/entities/app_notification.dart';

abstract class NotificationLocalDataSource {
  Future<List<AppNotification>> getNotifications();
  Future<void> saveNotifications(List<AppNotification> notifications);
  Future<void> clearNotifications();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _NOTIFICATIONS_KEY = 'app_notifications';

  NotificationLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final String? jsonString = sharedPreferences.getString(_NOTIFICATIONS_KEY);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw CacheException('Error al obtener notificaciones: $e');
    }
  }

  @override
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    try {
      final List<Map<String, dynamic>> jsonList = notifications.map((n) => n.toJson()).toList();
      final String jsonString = json.encode(jsonList);
      await sharedPreferences.setString(_NOTIFICATIONS_KEY, jsonString);
    } catch (e) {
      throw CacheException('Error al guardar notificaciones: $e');
    }
  }

  @override
  Future<void> clearNotifications() async {
    try {
      await sharedPreferences.remove(_NOTIFICATIONS_KEY);
    } catch (e) {
      throw CacheException('Error al limpiar notificaciones: $e');
    }
  }
}
