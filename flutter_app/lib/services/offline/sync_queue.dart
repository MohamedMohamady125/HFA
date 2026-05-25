import 'package:hive_flutter/hive_flutter.dart';

class SyncTask {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;
  final String? cacheInvalidationKey;

  SyncTask({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.cacheInvalidationKey,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'method': method, 'path': path,
    'data': data, 'createdAt': createdAt.millisecondsSinceEpoch,
    'retryCount': retryCount, 'cacheInvalidationKey': cacheInvalidationKey,
  };

  factory SyncTask.fromMap(Map<String, dynamic> map) => SyncTask(
    id: map['id'], method: map['method'], path: map['path'],
    data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    retryCount: map['retryCount'] ?? 0,
    cacheInvalidationKey: map['cacheInvalidationKey'],
  );

  SyncTask withRetry() => SyncTask(
    id: id, method: method, path: path, data: data,
    createdAt: createdAt, retryCount: retryCount + 1,
    cacheInvalidationKey: cacheInvalidationKey,
  );
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

  static List<SyncTask> getAll() {
    if (_box == null) return [];
    final tasks = _box!.values.map((v) => SyncTask.fromMap(Map<String, dynamic>.from(v))).toList();
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  static Future<void> remove(String id) async => await _box?.delete(id);

  static Future<void> update(SyncTask task) async => await _box?.put(task.id, task.toMap());

  static int get pendingCount => _box?.length ?? 0;
}
