import 'package:flutter/foundation.dart';

/// Holds the pending deep-link target from a tapped push notification.
/// The push handler sets it; the shell (athlete/coach) consumes it and
/// switches to the matching tab or pushes the matching route.
class DeepLink {
  DeepLink._();

  /// One of: 'thread', 'gear', 'attendance' — or null when nothing pending.
  static final ValueNotifier<String?> pending = ValueNotifier<String?>(null);

  static void set(String type) => pending.value = type;

  /// Returns the pending type and clears it.
  static String? consume() {
    final v = pending.value;
    pending.value = null;
    return v;
  }
}
