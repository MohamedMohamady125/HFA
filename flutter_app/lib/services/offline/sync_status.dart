import 'package:flutter/foundation.dart';
import 'sync_queue.dart';

/// Global observable sync/connectivity state.
/// Listened to by the app-wide OfflineStatusBar and any screen that
/// wants to react to connectivity or pending-sync changes.
class SyncStatus extends ChangeNotifier {
  SyncStatus._();
  static final SyncStatus instance = SyncStatus._();

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _failedCount = 0;
  DateTime? _lastSyncAt;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  int get failedCount => _failedCount;
  DateTime? get lastSyncAt => _lastSyncAt;

  void setOnline(bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    notifyListeners();
  }

  void setSyncing(bool syncing) {
    if (_isSyncing == syncing) return;
    _isSyncing = syncing;
    if (!syncing) _lastSyncAt = DateTime.now();
    notifyListeners();
  }

  /// Re-read pending/failed counts from the queue and notify if changed.
  void refreshCounts() {
    final pending = SyncQueue.pendingCount;
    final failed = SyncQueue.failedCount;
    if (pending == _pendingCount && failed == _failedCount) return;
    _pendingCount = pending;
    _failedCount = failed;
    notifyListeners();
  }
}
