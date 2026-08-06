import 'package:flutter/widgets.dart';

/// Global refresh signal. Fired when the app resumes from background or a
/// push notification arrives while the app is open. Screens that show live
/// data listen via [LiveRefreshMixin] and silently re-fetch.
class RefreshBus {
  RefreshBus._();

  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static void notify() => tick.value++;
}

/// Mixin for screens that should refresh when [RefreshBus] fires.
/// Implement [onLiveRefresh] with the screen's fetch method.
mixin LiveRefreshMixin<T extends StatefulWidget> on State<T> {
  void onLiveRefresh();

  void _onTick() {
    if (mounted) onLiveRefresh();
  }

  @override
  void initState() {
    super.initState();
    RefreshBus.tick.addListener(_onTick);
  }

  @override
  void dispose() {
    RefreshBus.tick.removeListener(_onTick);
    super.dispose();
  }
}
