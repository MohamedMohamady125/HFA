import 'package:hive_flutter/hive_flutter.dart';

class HiveCache {
  static Box? _box;

  /// Bumped whenever the cache is wiped (logout / branch switch).
  /// In-flight fetches capture the epoch before the request and must not
  /// write their result if the epoch changed — otherwise a slow response
  /// from the previous branch can repopulate the cache with stale data.
  static int epoch = 0;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox('cache');
    } catch (e) {
      // Hive init can fail on web or restricted environments
      _box = null;
    }
  }

  static String pathToKey(String path) =>
      path.replaceAll('/', '_').replaceAll(RegExp(r'^_'), '');

  static Future<void> put(String key, dynamic data, {Duration ttl = const Duration(hours: 24)}) async {
    await _box?.put(key, {
      'data': data,
      'expiry': DateTime.now().add(ttl).millisecondsSinceEpoch,
    });
  }

  static dynamic get(String key) {
    final entry = _box?.get(key);
    if (entry == null) return null;
    final map = Map<String, dynamic>.from(entry);
    final expiry = map['expiry'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      _box?.delete(key);
      return null;
    }
    return map['data'];
  }

  static bool has(String key) => get(key) != null;

  static Future<void> clearAll() async {
    epoch++;
    await _box?.clear();
  }

  static Future<void> clearPrefix(String prefix) async {
    if (_box == null) return;
    final keys = _box!.keys.where((k) => k.toString().startsWith(prefix)).toList();
    for (final k in keys) {
      await _box!.delete(k);
    }
  }
}
