import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
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
  bool loading = true;
  bool _fetched = false;

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
          lastThreadMessage = (p as List).isNotEmpty ? p[0]['message'] ?? '' : '';
        } catch (_) { lastThreadMessage = ''; }
      } else { lastThreadMessage = ''; }

      paymentStatus = (results[3] is Map ? results[3] as Map : {})[_dueDateKey()] ?? 'pending';
      _fetched = true;
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);

    if (loading) return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: List.generate(4, (_) => const ShimmerCard())))));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData, color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FadeSlideIn(child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.translate('dashboard'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text(DateFormat('EEEE, MMM d', l.locale.languageCode).format(DateTime.now()), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ])),
                GradientAvatar(name: 'HFA', size: 40),
              ])),
              const SizedBox(height: 24),

              FadeSlideIn(delay: 0, child: SectionHeader(title: l.translate('attendance'))),
              FadeSlideIn(delay: 30, child: ScaleOnTap(
                onTap: () => context.push('/athlete/attendance-history'),
                child: AppCard(
                  child: Column(
                    children: [
                      // This week summary
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(3, (i) => _attDay('${l.translate('day')} ${i + 1}', attendance.where((d) => d['day_number'] == i + 1).firstOrNull?['status']))),
                      const SizedBox(height: 14),
                      // Big obvious calendar button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(l.translate('view_full_calendar'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, color: AppColors.accent, size: 18),
                        ]),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 4),

              FadeSlideIn(delay: 50, child: SectionHeader(title: l.translate('latest_thread'))),
              FadeSlideIn(delay: 70, child: ScaleOnTap(onTap: () => AthleteTabSwitcher.of(context)?.switchTo(1), child: AppCard(child: Row(children: [
                _iconBox(Icons.forum_rounded, AppColors.info), const SizedBox(width: 12),
                Expanded(child: Text(lastThreadMessage.isEmpty ? l.translate('no_messages') : lastThreadMessage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
              ])))),
              const SizedBox(height: 4),

              FadeSlideIn(delay: 90, child: SectionHeader(title: l.translate('gear_check'))),
              FadeSlideIn(delay: 110, child: ScaleOnTap(onTap: () => AthleteTabSwitcher.of(context)?.switchTo(2), child: AppCard(child: Row(children: [
                _iconBox(Icons.backpack_rounded, AppColors.warning), const SizedBox(width: 12),
                Expanded(child: Text(gearMessage.isEmpty ? l.translate('no_gear_updates') : gearMessage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
              ])))),
              const SizedBox(height: 4),

              FadeSlideIn(delay: 130, child: SectionHeader(title: l.translate('payment'), subtitle: _monthName())),
              FadeSlideIn(delay: 150, child: AppCard(child: Row(children: [
                _iconBox(_paymentIcon(), _paymentColor()), const SizedBox(width: 12),
                Expanded(child: Text(l.translate('status'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
                StatusBadge(label: _paymentLabel(), color: _paymentColor()),
              ]))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) => Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18));

  Widget _attDay(String label, String? status) {
    final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(status == 'present' ? Icons.check_circle_rounded : status == 'absent' ? Icons.cancel_rounded : Icons.remove_circle_outline, color: color, size: 22)),
    ]);
  }

  Color _paymentColor() => switch (paymentStatus) { 'paid' => AppColors.success, 'late' => AppColors.error, _ => AppColors.warning };
  IconData _paymentIcon() => switch (paymentStatus) { 'paid' => Icons.check_circle, 'late' => Icons.warning_rounded, _ => Icons.schedule };
  String _paymentLabel() { final l = AppLocalizations.of(context); return switch (paymentStatus) { 'paid' => l.translate('paid'), 'late' => l.translate('late'), 'pending' => l.translate('pending'), _ => l.translate('unknown') }; }
}
