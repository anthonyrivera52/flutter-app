import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { connected, disconnected, connecting }

final connectivityStatusProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier(Connectivity());
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStatusProvider) ==
      ConnectivityStatus.connected;
});

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  ConnectivityNotifier(this._connectivity)
      : super(ConnectivityStatus.connecting) {
    _init();
  }

  void _init() async {
    final result = await _connectivity.checkConnectivity();
    _update(result);
    _sub = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    state = (results.isEmpty || results.contains(ConnectivityResult.none))
        ? ConnectivityStatus.disconnected
        : ConnectivityStatus.connected;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
