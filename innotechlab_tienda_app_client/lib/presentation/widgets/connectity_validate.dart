// En tu main.dart o en un widget que envuelva tu MaterialApp.router
// Asegúrate de que este widget sea un ConsumerWidget o ConsumerStatefulWidget
// si usas Riverpod y quieres acceder a networkInfoProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/network/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mi_tienda/service_locator.dart';

class MyAppWithConnectivityListener extends ConsumerStatefulWidget {
  final Widget child; // Tu MaterialApp.router iría aquí

  const MyAppWithConnectivityListener({super.key, required this.child});

  @override
  ConsumerState<MyAppWithConnectivityListener> createState() => _MyAppWithConnectivityListenerState();
}

class _MyAppWithConnectivityListenerState extends ConsumerState<MyAppWithConnectivityListener> {
  // Un "Key" para acceder al ScaffoldMessenger (necesario para SnackBar)
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  // Para guardar la referencia al SnackBar actual y evitar duplicados
  SnackBar? _noInternetSnackBar;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en la conectividad
    ref.read(networkInfoProvider).onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.every((result) => result == ConnectivityResult.none)) {
        // No hay conexión
        _showNoInternetSnackBar();
      } else {
        // Hay conexión
        _hideNoInternetSnackBar();
      }
    });
  }

  void _showNoInternetSnackBar() {
    // Si ya se está mostrando la Snackbar, no hacer nada
    if (_noInternetSnackBar != null) return;

    _noInternetSnackBar = SnackBar(
      content: Row(
        children: const [
          Icon(Icons.wifi_off, color: Colors.white),
          SizedBox(width: 10),
          Expanded(child: Text('Sin conexión a internet. Algunas funciones pueden no estar disponibles.', style: TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(days: 365), // Muestra la SnackBar indefinidamente
      behavior: SnackBarBehavior.fixed, // Asegura que se muestre en la parte inferior
    );
    _scaffoldMessengerKey.currentState?.showSnackBar(_noInternetSnackBar!);
  }

  void _hideNoInternetSnackBar() {
    if (_noInternetSnackBar != null) {
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _noInternetSnackBar = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger( // Necesario para mostrar SnackBar fuera de un Scaffold
      key: _scaffoldMessengerKey,
      child: widget.child,
    );
  }
}
