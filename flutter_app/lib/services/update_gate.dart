import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

/// Force-update gate. The server's MIN_APP_VERSION decides the oldest allowed
/// app version; anything older is locked on the update screen.
class UpdateGate {
  UpdateGate._();

  /// Non-null when an update is required. Holds the store URL ('' if unknown).
  static final ValueNotifier<String?> required = ValueNotifier<String?>(null);

  static Future<void> check() async {
    try {
      final res = await ApiService().get('/app/min-version');
      final min = res.data?['min_version']?.toString();
      if (min == null || min.isEmpty) return;
      final info = await PackageInfo.fromPlatform();
      if (_isOlder(info.version, min)) {
        final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
        final url = res.data[isIOS ? 'ios_url' : 'android_url'];
        required.value = url?.toString() ?? '';
      } else {
        required.value = null;
      }
    } catch (_) {
      // Network/server failures must never lock people out.
    }
  }

  static bool _isOlder(String current, String min) {
    List<int> parse(String v) =>
        v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final c = parse(current), m = parse(min);
    for (var i = 0; i < 3; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv != mv) return cv < mv;
    }
    return false;
  }
}
