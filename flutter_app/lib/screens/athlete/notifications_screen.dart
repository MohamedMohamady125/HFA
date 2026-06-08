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
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'thread': return AppColors.info;
      case 'gear': return AppColors.warning;
      default: return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasUnread = notifications.any((n) => n['read_status'] != true);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(l.translate('notifications'), style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(l.translate('mark_all_read'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(l.translate('no_notifications'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(l.translate('no_notifications_desc'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textTertiary)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: AppColors.accent,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      final isRead = n['read_status'] == true;
                      final type = n['type']?.toString();
                      final color = _colorForType(type);

                      return InkWell(
                        onTap: () => _markRead(n['id'], i),
                        child: Container(
                          color: isRead ? Colors.transparent : AppColors.accentLight.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_iconForType(type), color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeAgo(n['created_at']?.toString(), l),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 8),
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
    );
  }
}
