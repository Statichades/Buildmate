import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  ConnectivityService() {
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      if (!_connectionStatusController.isClosed) {
        _connectionStatusController.add(result != ConnectivityResult.none);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
