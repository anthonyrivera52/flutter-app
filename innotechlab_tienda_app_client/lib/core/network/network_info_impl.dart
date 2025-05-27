import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mi_tienda/core/network/network_info.dart';

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> isConnected() async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => connectivity.onConnectivityChanged;
}
