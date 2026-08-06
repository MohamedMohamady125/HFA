import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../api_service.dart';
import 'hive_cache.dart';
import 'sync_queue.dart';
import 'sync_status.dart';
import 'connectivity_service.dart';

/// Result of an offline-aware write.
/// [synced] true  → reached the server; [data] holds the response body.
/// [synced] false → saved locally and queued; will sync automatically.
class WriteResult {
  final bool synced;
  final dynamic data;
  const WriteResult({required this.synced, this.data});
}

class OfflineRepository {
  static final _api = ApiService();
  static const _uuid = Uuid();

  // ═══════════════════════════════════════════════════════
  // PREFETCH - Call after login to warm the cache
  // ═══════════════════════════════════════════════════════
  static Future<void> prefetchForUser(Map<String, dynamic> user) async {
    if (!ConnectivityService.isOnline) return;
    final role = user['role'];
    final branchId = user['branch_id'];
    final userId = user['id'];

    // Fire all in parallel - don't await individually
    final futures = <Future>[];
    futures.add(_prefetch('/users/me', ttl: const Duration(hours: 8)));

    if (role == 'athlete' && branchId != null) {
      futures.add(_prefetch('/attendance/athlete/$userId/week', ttl: const Duration(hours: 1)));
      futures.add(_prefetch('/gear/$branchId', ttl: const Duration(hours: 4)));
      futures.add(_prefetch('/threads/branch/$branchId', ttl: const Duration(hours: 1)));
      futures.add(_prefetch('/payments/$userId/status', ttl: const Duration(hours: 2)));
      futures.add(_prefetch('/branches/$branchId', ttl: const Duration(days: 1)));
      futures.add(_prefetch('/athlete/measurements', ttl: const Duration(hours: 8)));
      futures.add(_prefetch('/athlete/performance-logs', ttl: const Duration(hours: 8)));
      futures.add(_prefetch('/athlete/health-records', ttl: const Duration(hours: 8)));
      futures.add(_prefetch('/notifications/', cacheKey: 'notifications_list', ttl: const Duration(hours: 1)));
      final now = DateTime.now();
      futures.add(_prefetch('/attendance/athlete/$userId/month/${now.year}/${now.month}', ttl: const Duration(hours: 1)));
    } else if (role == 'coach' || role == 'head_coach') {
      if (branchId != null) {
        futures.add(_prefetch('/athletes/branch/$branchId/full', ttl: const Duration(hours: 4)));
        futures.add(_prefetch('/payments/summary/$branchId', ttl: const Duration(hours: 2)));
        futures.add(_prefetch('/attendance/branch/$branchId/session-dates', ttl: const Duration(hours: 2)));
        futures.add(_prefetch('/threads/branch/$branchId', ttl: const Duration(hours: 1)));
        futures.add(_prefetch('/gear/$branchId', ttl: const Duration(hours: 4)));
        futures.add(_prefetch('/users/requests', ttl: const Duration(hours: 1)));
        futures.add(_prefetch('/attendance/branch/$branchId/athletes-stats', ttl: const Duration(hours: 2)));
        final today = DateTime.now().toIso8601String().substring(0, 10);
        futures.add(_prefetch('/attendance/branch/$branchId/day/$today', ttl: const Duration(hours: 1)));
      }
      if (role == 'head_coach') {
        futures.add(_prefetch('/head-coach/branches', ttl: const Duration(days: 1)));
        futures.add(_prefetch('/head-coach/coaches', ttl: const Duration(hours: 4)));
      }
    }

    // Fire all, ignore individual failures
    await Future.wait(futures.map((f) => f.catchError((_) {})));
  }

  static Future<void> _prefetch(String path, {Duration ttl = const Duration(hours: 4), String? cacheKey}) async {
    try {
      final epoch = HiveCache.epoch;
      final res = await _api.get(path);
      if (HiveCache.epoch != epoch) return; // cache was wiped mid-flight (branch switch/logout)
      await HiveCache.put(cacheKey ?? HiveCache.pathToKey(path), res.data, ttl: ttl);
    } catch (_) {}
  }

  // Keys that were recently written to — don't let background refresh overwrite these
  static final Map<String, DateTime> _writeLocks = {};

  static bool _isWriteLocked(String key) {
    final lock = _writeLocks[key];
    if (lock == null) return false;
    if (DateTime.now().difference(lock).inSeconds > 3) {
      _writeLocks.remove(key);
      return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════
  // SYNC CACHE READ (instant, no await needed)
  // ═══════════════════════════════════════════════════════

  /// Returns cached data synchronously. Returns null if no cache.
  /// Use in initState to populate data before first build.
  static dynamic getCached(String path) {
    return HiveCache.get(HiveCache.pathToKey(path));
  }

  // ═══════════════════════════════════════════════════════
  // CACHED READ
  // ═══════════════════════════════════════════════════════

  /// Returns cached data immediately if available.
  /// Fetches fresh data in background and calls [onFresh] when ready.
  /// If no cache and offline, returns null.
  static Future<dynamic> cachedGet(
    String path, {
    String? cacheKey,
    Duration ttl = const Duration(hours: 4),
    Function(dynamic freshData)? onFresh,
  }) async {
    final key = cacheKey ?? HiveCache.pathToKey(path);

    // 1. Try cache first
    final cached = HiveCache.get(key);
    if (cached != null) {
      // Background refresh
      _refreshInBackground(path, key, ttl, onFresh);
      return cached;
    }

    // 2. No cache - fetch if online
    if (ConnectivityService.isOnline) {
      try {
        final epoch = HiveCache.epoch;
        final res = await _api.get(path);
        if (HiveCache.epoch == epoch) await HiveCache.put(key, res.data, ttl: ttl);
        return res.data;
      } catch (_) {
        return null;
      }
    }

    return null; // offline, no cache
  }

  static void _refreshInBackground(String path, String key, Duration ttl, Function(dynamic)? onFresh) {
    if (!ConnectivityService.isOnline) return;

    Future(() async {
      try {
        final epoch = HiveCache.epoch;
        final res = await _api.get(path);
        // Don't write if the cache was wiped mid-flight (branch switch/logout)
        // or a write just happened to this key.
        if (HiveCache.epoch == epoch && !_isWriteLocked(key)) {
          await HiveCache.put(key, res.data, ttl: ttl);
          onFresh?.call(res.data);
        }
      } catch (_) {}
    });
  }

  // ═══════════════════════════════════════════════════════
  // QUEUED WRITE
  // ═══════════════════════════════════════════════════════

  /// Tries to execute immediately if online.
  /// If offline or connection fails, queues for later sync.
  /// Applies optimistic update to local cache if provided.
  /// Throws DioException on real server errors (4xx/5xx while online) so
  /// callers can show a meaningful message.
  static Future<WriteResult> queueWrite({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    String? cacheInvalidationKey,
    String? optimisticCacheKey,
    String? label,
    dynamic Function(dynamic currentCache, Map<String, dynamic>? data)? optimisticUpdate,
  }) async {
    // 1. Optimistic local update
    if (optimisticCacheKey != null && optimisticUpdate != null) {
      final current = HiveCache.get(optimisticCacheKey);
      final updated = optimisticUpdate(current, data);
      if (updated != null) {
        await HiveCache.put(optimisticCacheKey, updated);
        _writeLocks[optimisticCacheKey] = DateTime.now(); // prevent background refresh from overwriting
      }
    }

    // 2. Try immediately if online
    if (ConnectivityService.isOnline) {
      try {
        Response? res;
        switch (method) {
          case 'POST': res = await _api.post(path, data: data);
          case 'PUT': res = await _api.put(path, data: data);
          case 'DELETE': res = await _api.delete(path);
        }
        if (cacheInvalidationKey != null) {
          await HiveCache.clearPrefix(cacheInvalidationKey);
        }
        return WriteResult(synced: true, data: res?.data);
      } on DioException catch (e) {
        if (e.type != DioExceptionType.connectionError &&
            e.type != DioExceptionType.connectionTimeout &&
            e.type != DioExceptionType.receiveTimeout) {
          rethrow; // real server error — caller shows the message
        }
        // Connection dropped mid-request — fall through to queue
      }
    }

    // 3. Queue for later
    await SyncQueue.enqueue(SyncTask(
      id: _uuid.v4(),
      method: method,
      path: path,
      data: data,
      createdAt: DateTime.now(),
      cacheInvalidationKey: cacheInvalidationKey,
      label: label,
    ));
    SyncStatus.instance.refreshCounts();

    return const WriteResult(synced: false); // queued
  }

  /// Extract a human-readable message from any error (Dio or otherwise).
  static String errorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) return data['detail'] as String;
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'No connection. Your change was not saved — please try again.';
      }
    }
    return fallback;
  }

  // ═══════════════════════════════════════════════════════
  // CONVENIENCE METHODS
  // ═══════════════════════════════════════════════════════

  // --- Attendance ---
  static Future<List> getAttendanceDay(int branchId, String date, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/attendance/branch/$branchId/day/$date', ttl: const Duration(hours: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<List> getAttendanceWeek(int userId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/attendance/athlete/$userId/week', ttl: const Duration(hours: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<List> getAttendanceMonth(int userId, int year, int month, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/attendance/athlete/$userId/month/$year/$month', ttl: const Duration(hours: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<List> getSessionDates(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/attendance/branch/$branchId/session-dates', ttl: const Duration(hours: 2), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<WriteResult> markAttendance(int athleteId, String sessionDate, String status, int branchId) =>
      queueWrite(
        method: 'POST', path: '/attendance/mark',
        data: {'athlete_id': athleteId, 'session_date': sessionDate, 'status': status},
        label: 'Attendance · $sessionDate',
        optimisticCacheKey: HiveCache.pathToKey('/attendance/branch/$branchId/day/$sessionDate'),
        optimisticUpdate: (cache, data) {
          if (cache is! List) return cache;
          return cache.map((item) {
            final m = Map<String, dynamic>.from(item);
            if (m['athlete_id'] == data?['athlete_id']) m['status'] = data?['status'];
            return m;
          }).toList();
        },
      );

  // --- Payments ---
  static Future<Map<String, dynamic>> getPaymentSummary(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/payments/summary/$branchId', ttl: const Duration(hours: 2), onFresh: onFresh);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static Future<WriteResult> markPayment(int athleteId, String sessionDate, String status, int branchId) =>
      queueWrite(
        method: 'POST', path: '/payments/mark',
        data: {'athlete_id': athleteId, 'session_date': sessionDate, 'status': status},
        label: 'Payment · $sessionDate',
        optimisticCacheKey: HiveCache.pathToKey('/payments/summary/$branchId'),
        optimisticUpdate: (cache, data) {
          if (cache is! Map) return cache;
          final m = Map<String, dynamic>.from(cache);
          final records = m['records'] as List? ?? [];
          for (var r in records) {
            if (r['athlete_id'] == data?['athlete_id']) {
              (r['statuses'] as Map?)?[sessionDate] = status;
              break;
            }
          }
          return m;
        },
      );

  // --- Threads ---
  static Future<List> getThreads(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/threads/branch/$branchId', ttl: const Duration(hours: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<List> getPosts(int threadId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/threads/$threadId/posts', ttl: const Duration(minutes: 30), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<WriteResult> postMessage(int threadId, String message) =>
      queueWrite(
        method: 'POST', path: '/threads/$threadId/post',
        data: {'message': message},
        cacheInvalidationKey: HiveCache.pathToKey('/threads/$threadId/posts'),
        label: 'Message',
      );

  // --- Gear ---
  static Future<Map<String, dynamic>> getGear(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/gear/$branchId', ttl: const Duration(hours: 4), onFresh: onFresh);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static Future<WriteResult> postGear(int branchId, String content) =>
      queueWrite(
        method: 'POST', path: '/gear/$branchId',
        data: {'content': content},
        cacheInvalidationKey: HiveCache.pathToKey('/gear/$branchId'),
        label: 'Gear update',
      );

  // --- Athletes ---
  static Future<List> getAthletesFull(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/athletes/branch/$branchId/full', ttl: const Duration(hours: 4), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<List> getAthletesStats(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/attendance/branch/$branchId/athletes-stats', ttl: const Duration(hours: 2), onFresh: onFresh);
    return data is List ? data : [];
  }

  // --- Branches ---
  static Future<List> getBranches({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/head-coach/branches', ttl: const Duration(days: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  // --- Coaches ---
  static Future<List> getCoaches({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/head-coach/coaches', ttl: const Duration(hours: 4), onFresh: onFresh);
    return data is List ? data : [];
  }

  // --- User ---
  static Future<Map<String, dynamic>> getUserMe({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/users/me', ttl: const Duration(hours: 8), onFresh: onFresh);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // --- Registration Requests ---
  static Future<List> getRequests({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/users/requests', ttl: const Duration(hours: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  // --- Payments (athlete) ---
  static Future<Map<String, dynamic>> getPaymentStatus(int userId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/payments/$userId/status', ttl: const Duration(hours: 2), onFresh: onFresh);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // --- Measurements ---
  static Future<dynamic> getMeasurements({Function(dynamic)? onFresh}) async {
    return await cachedGet('/athlete/measurements', ttl: const Duration(hours: 8), onFresh: onFresh);
  }

  // --- Performance Logs ---
  static Future<List> getPerformanceLogs({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/athlete/performance-logs', ttl: const Duration(hours: 8), onFresh: onFresh);
    return data is List ? data : [];
  }

  // --- Coach notes ---
  static Future<dynamic> getCoachNotes(int athleteId, {Function(dynamic)? onFresh}) async {
    return await cachedGet('/coach/notes/$athleteId', ttl: const Duration(hours: 8), onFresh: onFresh);
  }

  static Future<WriteResult> saveCoachNote(int athleteId, String note) =>
      queueWrite(
        method: 'POST', path: '/coach/notes',
        data: {'athlete_id': athleteId, 'note': note},
        cacheInvalidationKey: HiveCache.pathToKey('/coach/notes/$athleteId'),
        label: 'Coach note',
      );

  // --- Registration requests (approve/reject) ---
  static Future<WriteResult> approveRequest(int userId) => _decideRequest(userId, 'approve');
  static Future<WriteResult> rejectRequest(int userId) => _decideRequest(userId, 'reject');

  static Future<WriteResult> _decideRequest(int userId, String action) =>
      queueWrite(
        method: 'POST', path: '/users/$action/$userId',
        optimisticCacheKey: HiveCache.pathToKey('/users/requests'),
        optimisticUpdate: (cache, _) {
          if (cache is! List) return cache;
          return cache.where((r) => r is Map && r['id'] != userId).toList();
        },
        cacheInvalidationKey: HiveCache.pathToKey('/users/requests'),
        label: action == 'approve' ? 'Approve request' : 'Reject request',
      );

  // --- Health records ---
  static Future<List> getHealthRecords({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/athlete/health-records', ttl: const Duration(hours: 8), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<WriteResult> addHealthRecord(Map<String, dynamic> record) =>
      queueWrite(
        method: 'POST', path: '/athlete/health-records',
        data: record,
        cacheInvalidationKey: HiveCache.pathToKey('/athlete/health-records'),
        label: 'Health record',
      );

  static Future<WriteResult> deleteHealthRecord(int id) =>
      queueWrite(
        method: 'DELETE', path: '/athlete/health-records/$id',
        optimisticCacheKey: HiveCache.pathToKey('/athlete/health-records'),
        optimisticUpdate: (cache, _) {
          if (cache is! List) return cache;
          return cache.where((r) => r is Map && r['id'] != id).toList();
        },
        cacheInvalidationKey: HiveCache.pathToKey('/athlete/health-records'),
        label: 'Delete health record',
      );

  // --- Measurements / performance (writes) ---
  static Future<WriteResult> saveMeasurements(Map<String, dynamic> data) =>
      queueWrite(
        method: 'POST', path: '/athlete/measurements',
        data: data,
        cacheInvalidationKey: HiveCache.pathToKey('/athlete/measurements'),
        label: 'Measurements',
      );

  static Future<WriteResult> addPerformanceLog(Map<String, dynamic> data) =>
      queueWrite(
        method: 'POST', path: '/athlete/performance-log',
        data: data,
        cacheInvalidationKey: HiveCache.pathToKey('/athlete/performance-logs'),
        label: 'Performance log',
      );

  static Future<WriteResult> deletePerformanceLogs() =>
      queueWrite(
        method: 'DELETE', path: '/athlete/performance-logs',
        optimisticCacheKey: HiveCache.pathToKey('/athlete/performance-logs'),
        optimisticUpdate: (cache, _) => <dynamic>[],
        cacheInvalidationKey: HiveCache.pathToKey('/athlete/performance-logs'),
        label: 'Clear performance logs',
      );

  // --- Notifications ---
  static Future<List> getNotifications({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/notifications/', cacheKey: 'notifications_list',
        ttl: const Duration(hours: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<dynamic> getUnreadCount({Function(dynamic)? onFresh}) async {
    return await cachedGet('/notifications/unread-count', ttl: const Duration(minutes: 30), onFresh: onFresh);
  }

  static Future<WriteResult> markNotificationsReadAll() =>
      queueWrite(
        method: 'POST', path: '/notifications/read-all',
        cacheInvalidationKey: 'notifications',
        label: 'Mark notifications read',
      );

  static Future<WriteResult> markNotificationRead(int id) =>
      queueWrite(
        method: 'POST', path: '/notifications/read/$id',
        cacheInvalidationKey: 'notifications',
        label: 'Mark notification read',
      );

  // --- Profile ---
  static Future<WriteResult> updateCoachProfile(Map<String, dynamic> data) =>
      queueWrite(
        method: 'PUT', path: '/coach/profile',
        data: data,
        cacheInvalidationKey: HiveCache.pathToKey('/users/me'),
        label: 'Profile update',
      );

  // --- Public branches (guest page) ---
  static Future<List> getPublicBranches({Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/branches/', cacheKey: 'branches_public_list',
        ttl: const Duration(days: 1), onFresh: onFresh);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> getBranch(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/branches/$branchId', ttl: const Duration(days: 1), onFresh: onFresh);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // --- Sync status ---
  static int get pendingSyncCount => SyncQueue.pendingCount;
}
