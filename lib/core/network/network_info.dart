import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monitors device network connectivity.
class NetworkInfo {
  NetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});

final connectivityProvider = StreamProvider<bool>((ref) {
  return ref.watch(networkInfoProvider).onConnectivityChanged;
});

final isConnectedProvider = FutureProvider<bool>((ref) async {
  return ref.watch(networkInfoProvider).isConnected;
});
