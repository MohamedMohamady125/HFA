import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
import 'sync_queue.dart';
import 'hive_cache.dart';
import 'sync_status.dart';

class SyncEngine {
  static bool _processing = false;
  static const _maxRetries = 5;

  /// Flush all pending tasks in order. Never silently drops work:
  /// - connection errors stop the flush (still offline) and keep tasks
  /// - 4xx responses mark the task failed with the server's message
  /// - 5xx/unknown errors retry up to [_maxRetries], then mark failed
  static Future<void> flush() async {
    if (_processing) return;
    _processing = true;
    SyncStatus.instance.setSyncing(true);

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
          SyncStatus.instance.refreshCounts();
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            break; // still offline — keep everything, try again later
          }
          final status = e.response?.statusCode ?? 0;
          if (status >= 400 && status < 500) {
            // Permanent rejection — keep the task as "failed" so the user
            // can see what didn't make it and retry/discard it.
            await SyncQueue.update(task.copyWith(
              failed: true,
              lastError: _extractError(e) ?? 'Rejected by server ($status)',
            ));
            debugPrint('SyncEngine: task ${task.id} rejected ($status)');
          } else {
            // Server-side error — retry with a cap, then mark failed.
            if (task.retryCount + 1 >= _maxRetries) {
              await SyncQueue.update(task.copyWith(
                failed: true,
                retryCount: task.retryCount + 1,
                lastError: _extractError(e) ?? 'Server error ($status)',
              ));
            } else {
              await SyncQueue.update(task.withRetry());
            }
          }
        } catch (e) {
          debugPrint('SyncEngine: unexpected error: $e');
          if (task.retryCount + 1 >= _maxRetries) {
            await SyncQueue.update(
                task.copyWith(failed: true, retryCount: task.retryCount + 1, lastError: '$e'));
          } else {
            await SyncQueue.update(task.withRetry());
          }
        }
      }
    } finally {
      _processing = false;
      SyncStatus.instance.setSyncing(false);
      SyncStatus.instance.refreshCounts();
    }
  }

  /// Requeue all failed tasks and flush again (user-triggered retry).
  static Future<void> retryFailed() async {
    await SyncQueue.resetFailed();
    SyncStatus.instance.refreshCounts();
    await flush();
  }

  /// Discard all failed tasks (user gave up on them).
  static Future<void> discardFailed() async {
    await SyncQueue.discardFailed();
    SyncStatus.instance.refreshCounts();
  }

  static String? _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    return null;
  }
}
