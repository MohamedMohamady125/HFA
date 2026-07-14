import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _apply(dynamic data) {
    if (data is List) {
      notifications = data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  Future<void> _fetch() async {
    // Cache-first: returns cached instantly if present, refreshes in background
    final data = await OfflineRepository.getNotifications(onFresh: (fresh) {
      if (mounted) setState(() => _apply(fresh));
    });
    if (mounted) {
      setState(() {
        _apply(data);
        loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    HapticFeedback.lightImpact();
    // Optimistic UI update
    setState(() {
      for (var n in notifications) {
        n['read_status'] = true;
      }
    });
    try {
      await OfflineRepository.markNotificationsReadAll();
    } catch (_) {} // fire-and-forget
  }

  Future<void> _markRead(int id, int index) async {
    if (notifications[index]['read_status'] == true) return;
    setState(() => notifications[index]['read_status'] = true);
    try {
      await OfflineRepository.markNotificationRead(id);
    } catch (_) {} // fire-and-forget
  }

  String _timeAgo(String? createdAt, AppLocalizations l) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l.translate('just_now');
    if (diff.inMinutes < 60) return '${diff.inMinutes}${l.translate('minutes_ago')}';
    if (diff.inHours < 24) return '${diff.inHours}${l.translate('hours_ago')}';
    return '${diff.inDays}${l.translate('days_ago')}';
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'thread': return Icons.forum_rounded;
      case 'gear': return Icons.backpack_rounded;
      case 'attendance': return Icons.calendar_month_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'thread': return AppColors.info;
      case 'gear': return AppColors.warning;
      case 'attendance': return AppColors.success;
      default: return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasUnread = notifications.any((n) => n['read_status'] != true);
    final unreadCount = notifications.where((n) => n['read_status'] != true).length;

    return Scaffold(
      body: Column(
        children: [
          FadeSlideIn(
            child: HeroHeader(
              title: l.translate('notifications'),
              subtitle: hasUnread ? '$unreadCount ${l.translate('messages')}' : null,
              leading: HeaderIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
              trailing: hasUnread
                  ? TextButton(
                      onPressed: _markAllRead,
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: Text(l.translate('mark_all_read'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: loading
                ? const ShimmerList(count: 6)
                : notifications.isEmpty
                    ? (!ConnectivityService.isOnline
                        ? EmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: l.translate('no_connection'),
                            message: l.translate('no_connection_data'),
                          )
                        : EmptyState(
                            icon: Icons.notifications_off_rounded,
                            title: l.translate('no_notifications'),
                            message: l.translate('no_notifications_desc'),
                          ))
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        color: AppColors.accent,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: notifications.length,
                          itemBuilder: (_, i) {
                            final n = notifications[i];
                            final isRead = n['read_status'] == true;
                            final type = n['type']?.toString();
                            final color = _colorForType(type);

                            return _animatedItem(i, AppCard(
                                onTap: () => _markRead(n['id'], i),
                                color: isRead ? AppColors.cardBg : AppColors.accentLight.withValues(alpha: 0.35),
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    IconBadge(icon: _iconForType(type), color: color),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n['message']?.toString() ?? '',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                                              color: AppColors.textPrimary,
                                              height: 1.35,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            _timeAgo(n['created_at']?.toString(), l),
                                            style: AppTypography.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isRead)
                                      Padding(
                                        padding: const EdgeInsetsDirectional.only(top: 4, start: AppSpacing.sm),
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                        ),
                                      ),
                                  ],
                                ),
                              ));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Staggered entrance for list items (capped so long lists stay snappy).
  Widget _animatedItem(int i, Widget child) => child
      .animate(delay: (40 * (i > 8 ? 8 : i)).ms)
      .fadeIn(duration: 250.ms)
      .slideY(begin: 0.08, curve: Curves.easeOutCubic);
}
