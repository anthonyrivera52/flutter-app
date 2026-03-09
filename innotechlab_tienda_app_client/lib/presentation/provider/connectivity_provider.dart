import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity state enum
enum ConnectivityStatus {
  connected,
  disconnected,
  connecting,
}

/// Provider for connectivity stream
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Provider for current connectivity status
final connectivityStatusProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  final connectivity = Connectivity();
  return ConnectivityNotifier(connectivity);
});

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier(this._connectivity) : super(ConnectivityStatus.connecting) {
    _init();
  }

  void _init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = ConnectivityStatus.disconnected;
    } else {
      state = ConnectivityStatus.connected;
    }
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    final isConnected = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    state = isConnected ? ConnectivityStatus.connected : ConnectivityStatus.disconnected;
    return isConnected;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for checking if online
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status == ConnectivityStatus.connected;
});
