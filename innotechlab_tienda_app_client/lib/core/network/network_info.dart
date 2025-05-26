import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> isConnected();
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}