import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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

  Future<void> _fetch() async {
    setState(() => loading = true);
    try {
      final res = await ApiService().get('/notifications/');
      notifications = (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService().post('/notifications/read-all', data: {});
      for (var n in notifications) {
        n['read_status'] = true;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _markRead(int id, int index) async {
    if (notifications[index]['read_status'] == true) return;
    setState(() => notifications[index]['read_status'] = true);
    try {
      await ApiService().post('/notifications/read/$id', data: {});
    } catch (_) {}
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
                    ? EmptyState(
                        icon: Icons.notifications_off_rounded,
                        title: l.translate('no_notifications'),
                        message: l.translate('no_notifications_desc'),
                      )
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

                            return FadeSlideIn(
                              delay: i * 50,
                              child: AppCard(
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
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
