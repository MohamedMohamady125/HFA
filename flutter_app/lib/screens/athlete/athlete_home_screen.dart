import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'athlete_shell.dart';

class AthleteHomeScreen extends StatefulWidget {
  const AthleteHomeScreen({super.key});
  @override
  State<AthleteHomeScreen> createState() => AthleteHomeScreenState();
}

class AthleteHomeScreenState extends State<AthleteHomeScreen> with AutomaticKeepAliveClientMixin {
  List<dynamic> attendance = [];
  String gearMessage = '', lastThreadMessage = '';
  String? paymentStatus;
  String _userName = '';
  bool loading = true;
  bool _fetched = false;
  int _unreadCount = 0;

  @override
  bool get wantKeepAlive => true;

  String _dueDateKey() { final n = DateTime.now(); return '${n.year}-${n.month.toString().padLeft(2, '0')}-01'; }
  String _monthName() => DateFormat('MMMM yyyy', AppLocalizations.of(context).locale.languageCode).format(DateTime.now());

  @override
  void initState() {
    super.initState();
    // Sync cache read - instant data before first build
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) {
        final stored = p.getString('authUser');
        if (stored == null) return;
        final user = jsonDecode(stored);
        _userName = user['name']?.toString() ?? '';
        final cachedAtt = OfflineRepository.getCached('/attendance/athlete/${user['id']}/week');
        final cachedGear = OfflineRepository.getCached('/gear/${user['branch_id']}');
        final cachedPay = OfflineRepository.getCached('/payments/${user['id']}/status');
        if (cachedAtt is List) attendance = cachedAtt;
        if (cachedGear is Map) gearMessage = cachedGear['message']?.toString() ?? '';
        if (cachedPay is Map) paymentStatus = (cachedPay)[_dueDateKey()]?.toString() ?? 'pending';
        if (attendance.isNotEmpty || gearMessage.isNotEmpty) {
          _fetched = true;
          if (mounted) setState(() => loading = false);
        }
      });
    } catch (_) {}
    _fetchData();
  }

  // Called by shell on tab switch - silent refresh
  void silentRefresh() {
    if (_fetched) _fetchData(silent: true);
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent && !_fetched) setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final user = jsonDecode(stored);
      _userName = user['name']?.toString() ?? '';
      final attFuture = OfflineRepository.getAttendanceWeek(user['id']);
      final gearFuture = OfflineRepository.getGear(user['branch_id']);
      final threadsFuture = OfflineRepository.getThreads(user['branch_id']);
      final payFuture = OfflineRepository.getPaymentStatus(user['id']);

      final results = await Future.wait([attFuture, gearFuture, threadsFuture, payFuture]);

      attendance = results[0] is List ? results[0] as List : [];
      gearMessage = (results[1] is Map ? (results[1] as Map)['message'] : null) ?? '';

      final threads = (results[2] is List ? results[2] as List : []).where((t) => !(t['title'] as String).toLowerCase().contains('gear')).toList();
      if (threads.isNotEmpty) {
        try {
          final p = await OfflineRepository.getPosts(threads[0]['id']);
          lastThreadMessage = p.isNotEmpty ? p[0]['message'] ?? '' : '';
        } catch (_) { lastThreadMessage = ''; }
      } else { lastThreadMessage = ''; }

      paymentStatus = (results[3] is Map ? results[3] as Map : {})[_dueDateKey()] ?? 'pending';
      _fetched = true;

      // Fetch unread notification count (cache-first, silent failure → 0)
      try {
        final notif = await OfflineRepository.getUnreadCount(onFresh: (d) {
          if (mounted && d is Map) setState(() => _unreadCount = d['count'] ?? 0);
        });
        _unreadCount = (notif is Map ? notif['count'] : null) ?? 0;
      } catch (_) { _unreadCount = 0; }
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);

    if (loading) return const Scaffold(body: SafeArea(child: ShimmerList(count: 5)));

    final presentCount = attendance.where((d) => d['status'] == 'present').length;
    final absentCount = attendance.where((d) => d['status'] == 'absent').length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.accent,
        edgeOffset: 120,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: HeroHeader(
                  title: _userName.isEmpty ? l.translate('dashboard') : '${l.translate('hi')}, $_userName',
                  subtitle: DateFormat('EEEE, MMM d', l.locale.languageCode).format(DateTime.now()),
                  leading: GradientAvatar(name: _userName.isEmpty ? 'HFA' : _userName, size: 44),
                  trailing: HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    badgeCount: _unreadCount,
                    onTap: () async {
                      await context.push('/athlete/notifications');
                      _fetchData(silent: true);
                    },
                  ),
                  bottom: Row(children: [
                    StatChip(icon: Icons.check_circle_rounded, value: '$presentCount', label: l.translate('present')),
                    const SizedBox(width: AppSpacing.sm),
                    StatChip(icon: Icons.cancel_rounded, value: '$absentCount', label: l.translate('absent')),
                    const SizedBox(width: AppSpacing.sm),
                    StatChip(icon: _paymentIcon(), value: _paymentLabel(), label: l.translate('payment')),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 30),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FadeSlideIn(delay: 50, child: SectionHeader(title: l.translate('attendance'))),
                  FadeSlideIn(delay: 100, child: ScaleOnTap(
                    onTap: () => context.push('/athlete/attendance-history'),
                    child: AppCard(
                      child: Column(
                        children: [
                          // This week summary
                          Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(3, (i) => _attDay('${l.translate('day')} ${i + 1}', attendance.where((d) => d['day_number'] == i + 1).firstOrNull?['status']))),
                          const SizedBox(height: AppSpacing.lg),
                          // Big obvious calendar button
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l.translate('view_full_calendar'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, color: AppColors.accent, size: 18),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: AppSpacing.xs),

                  FadeSlideIn(delay: 150, child: SectionHeader(title: l.translate('latest_chat'))),
                  FadeSlideIn(delay: 200, child: ActionTile(
                    icon: Icons.forum_rounded,
                    color: AppColors.info,
                    title: l.translate('latest_chat'),
                    subtitle: lastThreadMessage.isEmpty ? l.translate('no_messages') : lastThreadMessage,
                    onTap: () => AthleteTabSwitcher.of(context)?.switchTo(1),
                  )),
                  const SizedBox(height: AppSpacing.xs),

                  FadeSlideIn(delay: 250, child: SectionHeader(title: l.translate('gear_check'))),
                  FadeSlideIn(delay: 300, child: ActionTile(
                    icon: Icons.backpack_rounded,
                    color: AppColors.warning,
                    title: l.translate('gear_check'),
                    subtitle: gearMessage.isEmpty ? l.translate('no_gear_updates') : gearMessage,
                    onTap: () => AthleteTabSwitcher.of(context)?.switchTo(2),
                  )),
                  const SizedBox(height: AppSpacing.xs),

                  FadeSlideIn(delay: 350, child: SectionHeader(title: l.translate('payment'), subtitle: _monthName())),
                  FadeSlideIn(delay: 400, child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                    child: Row(children: [
                      IconBadge(icon: _paymentIcon(), color: _paymentColor()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(l.translate('status'), style: AppTypography.titleMedium)),
                      StatusBadge(label: _paymentLabel(), color: _paymentColor()),
                    ]),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attDay(String label, String? status) {
    final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
    return Column(children: [
      Text(label, style: AppTypography.caption),
      const SizedBox(height: 6),
      Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(status == 'present' ? Icons.check_circle_rounded : status == 'absent' ? Icons.cancel_rounded : Icons.remove_circle_outline, color: color, size: 24)),
    ]);
  }

  Color _paymentColor() => switch (paymentStatus) { 'paid' => AppColors.success, 'late' => AppColors.error, _ => AppColors.warning };
  IconData _paymentIcon() => switch (paymentStatus) { 'paid' => Icons.check_circle, 'late' => Icons.warning_rounded, _ => Icons.schedule };
  String _paymentLabel() { final l = AppLocalizations.of(context); return switch (paymentStatus) { 'paid' => l.translate('paid'), 'late' => l.translate('late'), 'pending' => l.translate('pending'), _ => l.translate('unknown') }; }
}
