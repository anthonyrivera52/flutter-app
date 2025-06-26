// lib/services/connectivity_service.dart

import 'package:connectivity_plus/connectivity_plus.dart'; // Importa el paquete connectivity_plus

/// Clase de servicio para verificar el estado de la conexión a Internet.
/// Proporciona métodos para verificar la conectividad actual y escuchar sus cambios.
class ConnectivityService {
  /// Verifica si el dispositivo tiene algún tipo de conexión a Internet (Wi-Fi, datos móviles, Ethernet, etc.).
  /// Este método no garantiza acceso a un servidor específico, solo la existencia de una conexión de red activa.
  /// Retorna `true` si hay conexión, `false` de lo contrario.
  Future<bool> hasActiveInternetConnection() async {
    // Obtiene el estado actual de la conectividad. `checkConnectivity()` retorna una lista
    // porque un dispositivo puede tener múltiples tipos de conexión activos (ej. Wi-Fi y Ethernet).
    final connectivityResult = await (Connectivity().checkConnectivity());

    // Si la lista de resultados contiene `ConnectivityResult.none`, significa que no hay conexión de ningún tipo.
    if (connectivityResult.contains(ConnectivityResult.none)) {
      print('ConnectivityService: No hay ningún tipo de conexión a Internet.');
      return false;
    }

    // Si llegamos aquí, al menos un tipo de conexión está activo.
    // Para la mayoría de los casos, esto es suficiente para asumir que hay "internet".
    // Si se necesitara una verificación más profunda (ej. ping a un servidor conocido),
    // se podría añadir lógica adicional aquí, pero `connectivity_plus` ya es robusto.
    return true;
  }

  /// Retorna un `Stream` que emite el estado de la conectividad cada vez que cambia.
  /// Esto es útil para reaccionar a los cambios de conexión en tiempo real,
  /// por ejemplo, mostrando un mensaje cuando se pierde o se recupera la conexión.
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return Connectivity().onConnectivityChanged;
  }
}
