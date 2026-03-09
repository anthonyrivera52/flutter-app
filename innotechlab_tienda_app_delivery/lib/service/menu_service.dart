// lib/service/menu_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo para items del menú
class MenuItem {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String route;
  final String section;
  final int order;
  final bool isVisible;

  MenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.section,
    required this.order,
    this.isVisible = true,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      icon: map['icon'] as String,
      route: map['route'] as String,
      section: map['section'] as String,
      order: map['order'] as int? ?? 0,
      isVisible: map['is_visible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'route': route,
      'section': section,
      'order': order,
      'is_visible': isVisible,
    };
  }
}

/// Modelo para preferencias del usuario
class UserPreferences {
  final String userId;
  final int defaultTab;
  final bool notificationsEnabled;
  final String language;
  final bool darkMode;

  UserPreferences({
    required this.userId,
    this.defaultTab = 0,
    this.notificationsEnabled = true,
    this.language = 'es',
    this.darkMode = false,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      userId: map['user_id'] as String,
      defaultTab: map['default_tab'] as int? ?? 0,
      notificationsEnabled: map['notifications_enabled'] as bool? ?? true,
      language: map['language'] as String? ?? 'es',
      darkMode: map['dark_mode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'default_tab': defaultTab,
      'notifications_enabled': notificationsEnabled,
      'language': language,
      'dark_mode': darkMode,
    };
  }

  UserPreferences copyWith({
    String? userId,
    int? defaultTab,
    bool? notificationsEnabled,
    String? language,
    bool? darkMode,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      defaultTab: defaultTab ?? this.defaultTab,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

/// Servicio para manejar el menú y preferencias del usuario con Supabase
class MenuService {
  final SupabaseClient _supabaseClient;

  MenuService(this._supabaseClient);

  // ============================================
  // MENÚ
  // ============================================

  /// Obtiene los items del menú desde Supabase
  /// Si no existe la tabla, retorna menú por defecto
  Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await _supabaseClient
          .from('menu_items')
          .select()
          .eq('is_visible', true)
          .order('section')
          .order('order');

      return (response as List).map((item) => MenuItem.fromMap(item)).toList();
    } catch (e) {
      // Retorna menú por defecto si hay error
      return _getDefaultMenuItems();
    }
  }

  /// Obtiene las secciones del menú
  Future<List<String>> getMenuSections() async {
    try {
      final response = await _supabaseClient
          .from('menu_items')
          .select('section')
          .eq('is_visible', true);

      final sections = (response as List)
          .map((item) => item['section'] as String)
          .toSet()
          .toList();

      return sections.isEmpty ? _getDefaultSections() : sections;
    } catch (e) {
      return _getDefaultSections();
    }
  }

  /// Menú por defecto
  List<MenuItem> _getDefaultMenuItems() {
    return [
      // Principal
      MenuItem(id: 'home', title: 'Inicio', subtitle: 'Pantalla principal', icon: 'home', route: '/home', section: 'principal', order: 1),
      MenuItem(id: 'orders', title: 'Pedidos', subtitle: 'Historial de pedidos', icon: 'receipt', route: '/orders', section: 'principal', order: 2),

      // Finanzas
      MenuItem(id: 'wallet', title: 'Billetera', subtitle: 'Gestiona tu dinero', icon: 'wallet', route: '/wallet', section: 'finanzas', order: 1),
      MenuItem(id: 'earnings', title: 'Ganancias', subtitle: 'Ver tus ganancias', icon: 'trending_up', route: '/earnings', section: 'finanzas', order: 2),

      // Ajustes
      MenuItem(id: 'settings', title: 'Configuración', subtitle: 'Ajustes de la app', icon: 'settings', route: '/settings', section: 'ajustes', order: 1),
      MenuItem(id: 'help', title: 'Ayuda y Feedback', subtitle: 'Contáctanos', icon: 'help', route: '/help', section: 'ajustes', order: 2),
      MenuItem(id: 'courses', title: 'Cursos', subtitle: 'Mejora tus habilidades', icon: 'school', route: '/courses', section: 'aprende', order: 1),
    ];
  }

  List<String> _getDefaultSections() {
    return ['principal', 'finanzas', 'ajustes', 'aprende'];
  }

  // ============================================
  // PREFERENCIAS DEL USUARIO
  // ============================================

  /// Obtiene las preferencias del usuario
  Future<UserPreferences?> getUserPreferences(String userId) async {
    try {
      final response = await _supabaseClient
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return UserPreferences.fromMap(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Guarda o actualiza las preferencias del usuario
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      await _supabaseClient.from('user_preferences').upsert(
        preferences.toMap(),
        onConflict: 'user_id',
      );
    } catch (e) {
      // Silenciar error - las preferencias se guardan localmente
      print('Error guardando preferencias: $e');
    }
  }

  /// Actualiza una preferencia específica
  Future<void> updatePreference(String userId, String key, dynamic value) async {
    try {
      await _supabaseClient.from('user_preferences').update({
        key: value,
      }).eq('user_id', userId);
    } catch (e) {
      print('Error actualizando preferencia: $e');
    }
  }

  // ============================================
  // ESTADÍSTICAS DEL USUARIO
  // ============================================

  /// Guarda el último tab visitado
  Future<void> saveLastTab(String userId, int tabIndex) async {
    await updatePreference(userId, 'default_tab', tabIndex);
  }

  /// Obtiene estadísticas rápidas del usuario
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Obtener pedidos de hoy
      final today = DateTime.now().toIso8601String().split('T')[0];

      final ordersResponse = await _supabaseClient
          .from('orders')
          .select('id, total_amount, status')
          .eq('delivery_user_id', userId)
          .gte('created_at', '$today 00:00:00');

      final ordersToday = ordersResponse.length;
      final earningsToday = ordersResponse
          .where((o) => o['status'] == 'delivered')
          .fold<double>(0, (sum, o) => sum + (o['total_amount'] as num));

      return {
        'ordersToday': ordersToday,
        'earningsToday': earningsToday,
        'rating': 4.8, // Placeholder
      };
    } catch (e) {
      return {
        'ordersToday': 0,
        'earningsToday': 0.0,
        'rating': 4.8,
      };
    }
  }
}
