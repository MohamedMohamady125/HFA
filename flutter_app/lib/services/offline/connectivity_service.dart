import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_engine.dart';
import 'sync_queue.dart';
import 'sync_status.dart';

class ConnectivityService {
  static final _connectivity = Connectivity();
  static bool _isOnline = true;
  static Timer? _periodicFlush;

  static bool get isOnline => _isOnline;

  static Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _setOnline(!result.contains(ConnectivityResult.none));

    _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      final cameBackOnline = !_isOnline && online;
      _setOnline(online);
      if (cameBackOnline) SyncEngine.flush();
    });

    // Safety net: connectivity events can miss flaky/captive networks.
    // While work is pending and we believe we're online, retry every 30s.
    _periodicFlush = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline && SyncQueue.pendingCount > 0) SyncEngine.flush();
    });

    SyncStatus.instance.refreshCounts();
  }

  static void _setOnline(bool online) {
    _isOnline = online;
    SyncStatus.instance.setOnline(online);
  }

  /// Re-check connectivity and flush — call on app resume or manual retry.
  static Future<void> recheckAndFlush() async {
    final result = await _connectivity.checkConnectivity();
    _setOnline(!result.contains(ConnectivityResult.none));
    if (_isOnline) await SyncEngine.flush();
  }

  static void dispose() {
    _periodicFlush?.cancel();
  }
}
