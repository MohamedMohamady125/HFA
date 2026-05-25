import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
import 'sync_queue.dart';
import 'hive_cache.dart';

class SyncEngine {
  static bool _processing = false;

  static Future<void> flush() async {
    if (_processing) return;
    _processing = true;

    try {
      final tasks = SyncQueue.getAll();
      for (final task in tasks) {
        try {
          switch (task.method) {
            case 'POST':
              await ApiService().post(task.path, data: task.data);
            case 'PUT':
              await ApiService().put(task.path, data: task.data);
            case 'DELETE':
              await ApiService().delete(task.path);
          }
          await SyncQueue.remove(task.id);
          if (task.cacheInvalidationKey != null) {
            await HiveCache.clearPrefix(task.cacheInvalidationKey!);
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            break; // still offline, stop
          }
          // Server error - retry up to 3 times
          if (task.retryCount >= 3) {
            await SyncQueue.remove(task.id);
            debugPrint('SyncEngine: dropped task ${task.id} after 3 retries');
          } else {
            await SyncQueue.update(task.withRetry());
          }
        } catch (e) {
          debugPrint('SyncEngine: unexpected error: $e');
          if (task.retryCount >= 3) {
            await SyncQueue.remove(task.id);
          } else {
            await SyncQueue.update(task.withRetry());
          }
        }
      }
    } finally {
      _processing = false;
    }
  }
}
