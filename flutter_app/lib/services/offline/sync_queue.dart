import 'package:hive_flutter/hive_flutter.dart';

class SyncTask {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;
  final String? cacheInvalidationKey;

  /// Human-readable description shown in sync UI (e.g. "Attendance · Ahmed").
  final String? label;

  /// True when the server permanently rejected this task (4xx) or retries
  /// were exhausted. Failed tasks are kept (never silently dropped) so the
  /// user can retry or discard them.
  final bool failed;

  /// Last error message from the server, for display.
  final String? lastError;

  SyncTask({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.cacheInvalidationKey,
    this.label,
    this.failed = false,
    this.lastError,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'method': method, 'path': path,
    'data': data, 'createdAt': createdAt.millisecondsSinceEpoch,
    'retryCount': retryCount, 'cacheInvalidationKey': cacheInvalidationKey,
    'label': label, 'failed': failed, 'lastError': lastError,
  };

  factory SyncTask.fromMap(Map<String, dynamic> map) => SyncTask(
    id: map['id'], method: map['method'], path: map['path'],
    data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    retryCount: map['retryCount'] ?? 0,
    cacheInvalidationKey: map['cacheInvalidationKey'],
    label: map['label'],
    failed: map['failed'] ?? false,
    lastError: map['lastError'],
  );

  SyncTask copyWith({int? retryCount, bool? failed, String? lastError}) => SyncTask(
    id: id, method: method, path: path, data: data,
    createdAt: createdAt,
    retryCount: retryCount ?? this.retryCount,
    cacheInvalidationKey: cacheInvalidationKey,
    label: label,
    failed: failed ?? this.failed,
    lastError: lastError ?? this.lastError,
  );

  SyncTask withRetry() => copyWith(retryCount: retryCount + 1);
}

class SyncQueue {
  static Box? _box;

  static Future<void> init() async {
    try {
      _box = await Hive.openBox('sync_queue');
    } catch (_) {
      _box = null;
    }
  }

  static Future<void> enqueue(SyncTask task) async {
    await _box?.put(task.id, task.toMap());
  }

  static List<SyncTask> _all() {
    if (_box == null) return [];
    final tasks = _box!.values
        .map((v) => SyncTask.fromMap(Map<String, dynamic>.from(v)))
        .toList();
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  /// Tasks waiting to sync (excludes permanently failed ones).
  static List<SyncTask> getAll() => _all().where((t) => !t.failed).toList();

  /// Tasks the server rejected — kept for the user to retry or discard.
  static List<SyncTask> getFailed() => _all().where((t) => t.failed).toList();

  static Future<void> remove(String id) async => await _box?.delete(id);

  static Future<void> update(SyncTask task) async => await _box?.put(task.id, task.toMap());

  /// Move all failed tasks back into the pending queue for another attempt.
  static Future<void> resetFailed() async {
    for (final t in getFailed()) {
      await update(t.copyWith(failed: false, retryCount: 0));
    }
  }

  /// Permanently discard all failed tasks.
  static Future<void> discardFailed() async {
    for (final t in getFailed()) {
      await remove(t.id);
    }
  }

  static int get pendingCount => getAll().length;
  static int get failedCount => getFailed().length;
}
