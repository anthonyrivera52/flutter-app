import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Enum para tipos de módulo donde puede ocurrir un error
enum ErrorModule {
  auth('Autenticación'),
  home('Home'),
  cart('Carrito'),
  checkout('Checkout'),
  orders('Pedidos'),
  profile('Perfil'),
  location('Ubicación'),
  payment('Pago'),
  products('Productos'),
  unknown('Desconocido');

  final String displayName;
  const ErrorModule(this.displayName);
}

/// Enum para acciones realizadas cuando ocurrió el error
enum ErrorAction {
  login('Iniciar sesión'),
  register('Registrarse'),
  loadProducts('Cargar productos'),
  loadShops('Cargar tiendas'),
  addToCart('Agregar al carrito'),
  placeOrder('Realizar pedido'),
  getLocation('Obtener ubicación'),
  loadOrders('Cargar pedidos'),
  updateProfile('Actualizar perfil'),
  payment('Procesar pago'),
  unknown('Desconocida');

  final String displayName;
  const ErrorAction(this.displayName);
}

/// Entidad para registrar errores en la aplicación
class AppError {
  final String id;
  final String userId;
  final String module;
  final String action;
  final String errorMessage;
  final String stackTrace;
  final DateTime timestampUtc;
  final String? additionalData;

  const AppError({
    required this.id,
    required this.userId,
    required this.module,
    required this.action,
    required this.errorMessage,
    required this.stackTrace,
    required this.timestampUtc,
    this.additionalData,
  });

  /// Convertir a JSON para guardar en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'module': module,
      'action': action,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'timestamp_utc': timestampUtc.toIso8601String(),
      'additional_data': additionalData,
    };
  }

  /// Crear desde JSON de Supabase
  factory AppError.fromJson(Map<String, dynamic> json) {
    return AppError(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      module: json['module'] as String,
      action: json['action'] as String,
      errorMessage: json['error_message'] as String,
      stackTrace: json['stack_trace'] as String,
      timestampUtc: DateTime.parse(json['timestamp_utc'] as String),
      additionalData: json['additional_data'] as String?,
    );
  }
}

/// Servicio para registrar y gestionar errores de la aplicación
/// Envía los errores a Supabase para su análisis
class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  final _uuid = const Uuid();
  SupabaseClient? _supabase;

  /// Inicializar el servicio con Supabase
  void initialize(SupabaseClient supabase) {
    _supabase = supabase;
  }

  /// Registrar un error en la aplicación
  Future<void> logError({
    required String userId,
    required ErrorModule module,
    required ErrorAction action,
    required String errorMessage,
    String? stackTrace,
    String? additionalData,
  }) async {
    final error = AppError(
      id: _uuid.v4(),
      userId: userId,
      module: module.displayName,
      action: action.displayName,
      errorMessage: errorMessage,
      stackTrace: stackTrace ?? '',
      timestampUtc: DateTime.now().toUtc(),
      additionalData: additionalData,
    );

    debugPrint('ERROR REGISTRADO: [$module] $action - $errorMessage');

    if (_supabase != null) {
      try {
        await _supabase!.from('app_errors').insert(error.toJson());
      } catch (e) {
        debugPrint('Error al guardar en Supabase: $e');
      }
    }
  }

  /// Registrar un error capturado (catch)
  Future<void> logCaughtError({
    required String userId,
    required ErrorModule module,
    required ErrorAction action,
    required Object error,
    StackTrace? stackTrace,
    String? additionalData,
  }) async {
    await logError(
      userId: userId,
      module: module,
      action: action,
      errorMessage: error.toString(),
      stackTrace: stackTrace?.toString(),
      additionalData: additionalData,
    );
  }

  /// Obtener errores del usuario desde Supabase
  Future<List<AppError>> getUserErrors(String userId, {int limit = 50}) async {
    if (_supabase == null) return [];

    try {
      final response = await _supabase!
          .from('app_errors')
          .select()
          .eq('user_id', userId)
          .order('timestamp_utc', ascending: false)
          .limit(limit);

      final data = response as List;
      return data.map((json) => AppError.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error al obtener errores: $e');
      return [];
    }
  }

  /// Obtener todos los errores (para admins)
  Future<List<AppError>> getAllErrors({
    int limit = 100,
    DateTime? fromDate,
    String? moduleFilter,
  }) async {
    if (_supabase == null) return [];

    try {
      List<dynamic> response;

      if (fromDate != null && moduleFilter != null) {
        response = await _supabase!
            .from('app_errors')
            .select()
            .gte('timestamp_utc', fromDate.toIso8601String())
            .eq('module', moduleFilter)
            .order('timestamp_utc', ascending: false)
            .limit(limit);
      } else if (fromDate != null) {
        response = await _supabase!
            .from('app_errors')
            .select()
            .gte('timestamp_utc', fromDate.toIso8601String())
            .order('timestamp_utc', ascending: false)
            .limit(limit);
      } else if (moduleFilter != null) {
        response = await _supabase!
            .from('app_errors')
            .select()
            .eq('module', moduleFilter)
            .order('timestamp_utc', ascending: false)
            .limit(limit);
      } else {
        response = await _supabase!
            .from('app_errors')
            .select()
            .order('timestamp_utc', ascending: false)
            .limit(limit);
      }

      return response.map((json) => AppError.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error al obtener errores: $e');
      return [];
    }
  }
}

/// Instancia global del logger de errores
final errorLogger = ErrorLogger();
