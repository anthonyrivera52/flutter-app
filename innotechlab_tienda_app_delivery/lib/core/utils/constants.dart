// lib/core/utils/constants.dart
// Constantes de la aplicación - configurables por entorno

import 'package:flutter/foundation.dart';

class AppConstants {
  // ===== CONFIGURACIÓN DE ENTORNO =====

  // Determinar si es modo desarrollo
  static const bool isDevelopment = kDebugMode;

  // ===== SUPABASE =====
  // Estas se cargan desde .env en main.dart
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';
  static String supabaseBucket = '';

  // ===== OTP CONFIGURATION =====
  // 'supabase' para desarrollo, 'twilio' para producción
  static String otpMethod = 'supabase';

  // Para desarrollo: código OTP fijo (ignorado en producción)
  static const String devOtpCode = '123456';

  // Para Twilio (producción): configurar con tus credenciales
  static String twilioAccountSid = '';
  static String twilioAuthToken = '';
  static String twilioPhoneNumber = '';

  // ===== TABLA DE PEDIDOS =====
  // Nombre de la tabla a escuchar (puede ser 'sales' o 'orders')
  // IMPORTANTE: La tabla 'orders' no existe, usar 'sales' con delivery_orders
  static String ordersTable = 'sales';
  static String deliveryOrdersTable = 'delivery_orders';

  // ===== DELIVERY ORDERS STATUS =====
  static const String deliveryStatusPending = 'pending';
  static const String deliveryStatusAssigned = 'assigned';
  static const String deliveryStatusAccepted = 'accepted';
  static const String deliveryStatusArrivedAtRestaurant = 'arrived_at_restaurant';
  static const String deliveryStatusPickingUp = 'picking_up';
  static const String deliveryStatusPickedUp = 'picked_up';
  static const String deliveryStatusDelivering = 'delivering';
  static const String deliveryStatusDelivered = 'delivered';
  static const String deliveryStatusCancelled = 'cancelled';

  // Estados activos para pedidos de delivery
  static const List<String> activeDeliveryStatuses = [
    'assigned',
    'accepted',
    'arrived_at_restaurant',
    'picking_up',
    'picked_up',
    'delivering'
  ];

  // Estados de venta en Supabase (order_status enum)
  static const List<String> saleStatusesPending = ['NEW', 'PENDING', 'CONFIRMED'];
  static const List<String> saleStatusesInProgress = ['PREPARING', 'READY', 'ACCEPTED'];

  // ===== GEOFENCING =====
  static double defaultMaxRadiusKm = 5.0;
  static double maxRadiusKmDevelopment = 10.0; // Mayor radio en desarrollo para pruebas
  static double maxRadiusKmProduction = 5.0;   // Radio menor en producción

  // ===== CÓDIGOS DE VERIFICACIÓN =====
  // Para desarrollo: códigos fijos
  static const String devPickupCode = '1234';
  static const String devDeliveryCode = '0000';

  // Para producción: estos deben validarse desde el backend
  static bool validatePickupCode(String code) {
    if (isDevelopment) {
      return code == devPickupCode;
    }
    // En producción, la validación se hace en el backend
    return code.isNotEmpty;
  }

  static bool validateDeliveryCode(String code) {
    if (isDevelopment) {
      return code == devDeliveryCode;
    }
    // En producción, la validación se hace en el backend
    return code.isNotEmpty;
  }

  // ===== CONFIGURACIÓN DE MAPAS =====
  // Ubicación por defecto (Sabaneta, Antioquia, Colombia)
  static const double defaultLatitude = 6.195618;
  static const double defaultLongitude = -75.575971;
  static const double defaultZoom = 14.4746;

  // ===== UI CONFIGURATION =====
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // ===== ORDEN STATUS =====
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusArrivedAtRestaurant = 'arrived_at_restaurant';
  static const String statusPickingUp = 'picking_up';
  static const String statusPickedUp = 'picked_up';
  static const String statusDelivering = 'delivering';
  static const String statusDelivered = 'delivered';
  static const String statusRejected = 'rejected';
  static const String statusCancelled = 'cancelled';

  // Lista de estados activos (para filtrar pedidos)
  static const List<String> activeOrderStatuses = [
    'accepted',
    'arrived_at_restaurant',
    'picking_up',
    'picked_up',
    'delivering'
  ];

  // ===== NOTIFICATIONS =====
  static const int newOrderNotificationId = 0;
  static const int orderStatusNotificationId = 1;

  // ===== MÉTODOS DE INICIALIZACIÓN =====

  /// Inicializar constantes desde variables de entorno
  static void initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required String supabaseBucket,
    required String otpMethod,
    String? twilioAccountSid,
    String? twilioAuthToken,
    String? twilioPhoneNumber,
    String? ordersTable,
  }) {
    AppConstants.supabaseUrl = supabaseUrl;
    AppConstants.supabaseAnonKey = supabaseAnonKey;
    AppConstants.supabaseBucket = supabaseBucket;
    AppConstants.otpMethod = otpMethod;

    if (twilioAccountSid != null) twilioAccountSid = twilioAccountSid;
    if (twilioAuthToken != null) twilioAuthToken = twilioAuthToken;
    if (twilioPhoneNumber != null) twilioPhoneNumber = twilioPhoneNumber;
    if (ordersTable != null) AppConstants.ordersTable = ordersTable;
  }

  /// Obtener el radio máximo según el entorno
  static double get maxRadius => isDevelopment ? maxRadiusKmDevelopment : maxRadiusKmProduction;

  /// Verificar si el método OTP es Supabase
  static bool get isSupabaseOtp => otpMethod.toLowerCase() == 'supabase';

  /// Verificar si el método OTP es Twilio
  static bool get isTwilioOtp => otpMethod.toLowerCase() == 'twilio';
}
