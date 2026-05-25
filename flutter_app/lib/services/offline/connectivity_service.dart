import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_engine.dart';

class ConnectivityService {
  static final _connectivity = Connectivity();
  static bool _isOnline = true;

  static bool get isOnline => _isOnline;

  static Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (!_isOnline && online) {
        SyncEngine.flush();
      }
      _isOnline = online;
    });
  }
}
