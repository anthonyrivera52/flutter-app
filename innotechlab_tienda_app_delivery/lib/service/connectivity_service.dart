// lib/service/connectivity_service.dart

import 'package:connectivity_plus/connectivity_plus.dart'; // Importa el paquete connectivity_plus

/// Clase de servicio para verificar el estado de la conexión a Internet.
/// Proporciona métodos para verificar la conectividad actual y escuchar sus cambios.
class ConnectivityService {
  /// Verifica si el dispositivo tiene algún tipo de conexión a Internet (Wi-Fi, datos móviles, Ethernet, etc.).
  /// Este método no garantiza acceso a un servidor específico, solo la existencia de una conexión de red activa.
  /// Retorna `true` si hay conexión, `false` de lo contrario.
  Future<bool> hasActiveInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      // print('ConnectivityService: No hay ningún tipo de conexión a Internet.'); // Descomentar para depuración
      return false;
    }
    return true;
  }

  /// Retorna un `Stream` que emite el estado de la conectividad cada vez que cambia.
  /// Esto es útil para reaccionar a los cambios de conexión en tiempo real,
  /// por ejemplo, mostrando un mensaje cuando se pierde o se recupera la conexión.
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return Connectivity().onConnectivityChanged;
  }
}