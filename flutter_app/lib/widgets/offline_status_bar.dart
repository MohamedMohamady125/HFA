import 'package:flutter/material.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';
import '../services/offline/connectivity_service.dart';
import '../theme/app_theme.dart';

/// App-wide banner that reflects connectivity + sync state.
/// Wraps the whole app (via MaterialApp.builder) so it appears on every
/// screen without individual screens needing to manage it.
///
/// States:
///  - offline               → dark banner "You're offline — changes are saved..."
///  - online + syncing      → cyan banner "Syncing N changes…"
///  - online + failed tasks → red banner with Retry / Discard actions
///  - all good              → nothing (zero height)
class OfflineStatusBar extends StatelessWidget {
  final Widget child;
  const OfflineStatusBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SyncStatus.instance,
      builder: (context, _) {
        final s = SyncStatus.instance;
        Widget? banner;

        if (!s.isOnline) {
          banner = _Banner(
            key: const ValueKey('offline'),
            color: const Color(0xFF37474F),
            icon: Icons.cloud_off_rounded,
            text: s.pendingCount > 0
                ? "You're offline — ${s.pendingCount} change${s.pendingCount == 1 ? '' : 's'} saved, will sync automatically"
                : "You're offline — changes will be saved and synced later",
          );
        } else if (s.isSyncing && s.pendingCount > 0) {
          banner = _Banner(
            key: const ValueKey('syncing'),
            color: AppColors.accent,
            icon: Icons.sync_rounded,
            spinning: true,
            text: 'Syncing ${s.pendingCount} change${s.pendingCount == 1 ? '' : 's'}…',
          );
        } else if (s.failedCount > 0) {
          banner = _Banner(
            key: const ValueKey('failed'),
            color: const Color(0xFFC62828),
            icon: Icons.error_outline_rounded,
            text: '${s.failedCount} change${s.failedCount == 1 ? '' : 's'} could not sync',
            actions: [
              _BannerAction(label: 'Retry', onTap: () => SyncEngine.retryFailed()),
              _BannerAction(label: 'Discard', onTap: () => SyncEngine.discardFailed()),
            ],
          );
        } else if (s.pendingCount > 0) {
          banner = _Banner(
            key: const ValueKey('pending'),
            color: const Color(0xFFF59E0B),
            icon: Icons.schedule_rounded,
            text: '${s.pendingCount} change${s.pendingCount == 1 ? '' : 's'} waiting to sync',
            actions: [
              _BannerAction(label: 'Sync now', onTap: () => ConnectivityService.recheckAndFlush()),
            ],
          );
        }

        return Directionality(
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => SizeTransition(
                  sizeFactor: anim,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: banner ?? const SizedBox.shrink(),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool spinning;
  final List<_BannerAction> actions;

  const _Banner({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
    this.spinning = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Material(
      color: color,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 6, 16, 8),
        child: Row(
          children: [
            spinning
                ? const _SpinningIcon()
                : Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final a in actions) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: a.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.label,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerAction {
  final String label;
  final VoidCallback onTap;
  const _BannerAction({required this.label, required this.onTap});
}

class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon();

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
    );
  }
}
