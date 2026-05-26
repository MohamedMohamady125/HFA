import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../api_service.dart';
import 'hive_cache.dart';
import 'sync_queue.dart';
import 'sync_engine.dart';
import 'connectivity_service.dart';

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
    } else if (role == 'coach' || role == 'head_coach') {
      if (branchId != null) {
        futures.add(_prefetch('/athletes/branch/$branchId/full', ttl: const Duration(hours: 4)));
        futures.add(_prefetch('/payments/summary/$branchId', ttl: const Duration(hours: 2)));
        futures.add(_prefetch('/attendance/branch/$branchId/session-dates', ttl: const Duration(hours: 2)));
        futures.add(_prefetch('/threads/branch/$branchId', ttl: const Duration(hours: 1)));
        futures.add(_prefetch('/gear/$branchId', ttl: const Duration(hours: 4)));
        futures.add(_prefetch('/users/requests', ttl: const Duration(hours: 1)));
      }
      if (role == 'head_coach') {
        futures.add(_prefetch('/head-coach/branches', ttl: const Duration(days: 1)));
        futures.add(_prefetch('/head-coach/coaches', ttl: const Duration(hours: 4)));
      }
    }

    // Fire all, ignore individual failures
    await Future.wait(futures.map((f) => f.catchError((_) {})));
  }

  static Future<void> _prefetch(String path, {Duration ttl = const Duration(hours: 4)}) async {
    try {
      final res = await _api.get(path);
      await HiveCache.put(HiveCache.pathToKey(path), res.data, ttl: ttl);
    } catch (_) {}
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
        final res = await _api.get(path);
        await HiveCache.put(key, res.data, ttl: ttl);
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
        final res = await _api.get(path);
        await HiveCache.put(key, res.data, ttl: ttl);
        onFresh?.call(res.data);
      } catch (_) {}
    });
  }

  // ═══════════════════════════════════════════════════════
  // QUEUED WRITE
  // ═══════════════════════════════════════════════════════

  /// Tries to execute immediately if online.
  /// If offline or connection fails, queues for later sync.
  /// Applies optimistic update to local cache if provided.
  static Future<dynamic> queueWrite({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    String? cacheInvalidationKey,
    String? optimisticCacheKey,
    dynamic Function(dynamic currentCache, Map<String, dynamic>? data)? optimisticUpdate,
  }) async {
    // 1. Optimistic local update
    if (optimisticCacheKey != null && optimisticUpdate != null) {
      final current = HiveCache.get(optimisticCacheKey);
      final updated = optimisticUpdate(current, data);
      if (updated != null) await HiveCache.put(optimisticCacheKey, updated);
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
        // Invalidate cache so next read gets fresh
        if (cacheInvalidationKey != null) {
          await HiveCache.clearPrefix(cacheInvalidationKey);
        }
        return res?.data;
      } on DioException catch (e) {
        if (e.type != DioExceptionType.connectionError &&
            e.type != DioExceptionType.connectionTimeout) {
          rethrow; // real server error
        }
        // Fall through to queue
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
    ));

    return null; // queued
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

  static Future<void> markAttendance(int athleteId, String sessionDate, String status, int branchId) =>
      queueWrite(
        method: 'POST', path: '/attendance/mark',
        data: {'athlete_id': athleteId, 'session_date': sessionDate, 'status': status},
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

  static Future<void> markPayment(int athleteId, String sessionDate, String status, int branchId) =>
      queueWrite(
        method: 'POST', path: '/payments/mark',
        data: {'athlete_id': athleteId, 'session_date': sessionDate, 'status': status},
        cacheInvalidationKey: HiveCache.pathToKey('/payments/summary/$branchId'),
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

  static Future<void> postMessage(int threadId, String message) =>
      queueWrite(
        method: 'POST', path: '/threads/$threadId/post',
        data: {'message': message},
        cacheInvalidationKey: HiveCache.pathToKey('/threads/$threadId/posts'),
      );

  // --- Gear ---
  static Future<Map<String, dynamic>> getGear(int branchId, {Function(dynamic)? onFresh}) async {
    final data = await cachedGet('/gear/$branchId', ttl: const Duration(hours: 4), onFresh: onFresh);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static Future<void> postGear(int branchId, String content) =>
      queueWrite(
        method: 'POST', path: '/gear/$branchId',
        data: {'content': content},
        cacheInvalidationKey: HiveCache.pathToKey('/gear/$branchId'),
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

  // --- Sync status ---
  static int get pendingSyncCount => SyncQueue.pendingCount;
}
