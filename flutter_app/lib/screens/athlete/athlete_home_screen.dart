import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AthleteHomeScreen extends StatefulWidget {
  const AthleteHomeScreen({super.key});
  @override
  State<AthleteHomeScreen> createState() => _AthleteHomeScreenState();
}

class _AthleteHomeScreenState extends State<AthleteHomeScreen> {
  List<dynamic> attendance = [];
  String gearMessage = '', lastThreadMessage = '';
  String? paymentStatus;
  bool loading = true;

  String _dueDateKey() { final n = DateTime.now(); return '${n.year}-${n.month.toString().padLeft(2, '0')}-01'; }
  String _monthName() => DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  void initState() { super.initState(); _fetchData(); }

  Future<void> _fetchData() async {
    if (!loading) setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final user = jsonDecode(stored);
      final dio = Dio();
      final h = {'Authorization': 'Bearer ${user['token']}'};
      final base = ApiService.baseUrl;

      final results = await Future.wait([
        dio.get('$base/attendance/athlete/${user['id']}/week', options: Options(headers: h)).catchError((_) => Response(requestOptions: RequestOptions(), data: [])),
        dio.get('$base/gear/${user['branch_id']}', options: Options(headers: h)).catchError((_) => Response(requestOptions: RequestOptions(), data: {})),
        dio.get('$base/threads/branch/${user['branch_id']}', options: Options(headers: h)).catchError((_) => Response(requestOptions: RequestOptions(), data: [])),
        dio.get('$base/payments/${user['id']}/status', options: Options(headers: h)).catchError((_) => Response(requestOptions: RequestOptions(), data: {})),
      ]);

      attendance = results[0].data is List ? results[0].data : [];
      gearMessage = results[1].data?['message'] ?? 'No gear updates.';

      final threads = (results[2].data is List ? results[2].data as List : []).where((t) => !(t['title'] as String).toLowerCase().contains('gear')).toList();
      if (threads.isNotEmpty) {
        try {
          final p = await dio.get('$base/threads/${threads[0]['id']}/posts', options: Options(headers: h));
          lastThreadMessage = (p.data as List).isNotEmpty ? p.data[0]['message'] ?? '' : 'No posts yet.';
        } catch (_) { lastThreadMessage = 'No posts yet.'; }
      } else { lastThreadMessage = 'No threads available.'; }

      paymentStatus = (results[3].data is Map ? results[3].data : {})[_dueDateKey()] ?? 'pending';
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (loading) {
      return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ShimmerCard(), const ShimmerCard(), const ShimmerCard(), const ShimmerCard(),
      ]))));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.translate('dashboard'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(DateFormat('EEEE, MMM d').format(DateTime.now()), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ])),
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.pool_rounded, color: AppColors.accent, size: 20)),
                ])),
                const SizedBox(height: 24),

                FadeSlideIn(delay: 100, child: SectionHeader(title: l.translate('weekly_attendance'))),
                FadeSlideIn(delay: 150, child: AppCard(child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(3, (i) {
                    final record = attendance.where((d) => d['day_number'] == i + 1).firstOrNull;
                    return _attDay('${l.translate('day')} ${i + 1}', record?['status']);
                  }),
                ))),
                const SizedBox(height: 4),

                FadeSlideIn(delay: 200, child: SectionHeader(title: l.translate('latest_thread'))),
                FadeSlideIn(delay: 250, child: ScaleOnTap(onTap: () => context.go('/athlete/threads'), child: AppCard(child: Row(children: [
                  _iconBox(Icons.forum_rounded, AppColors.info), const SizedBox(width: 12),
                  Expanded(child: Text(lastThreadMessage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                ])))),
                const SizedBox(height: 4),

                FadeSlideIn(delay: 300, child: SectionHeader(title: l.translate('gear_check'))),
                FadeSlideIn(delay: 350, child: ScaleOnTap(onTap: () => context.go('/athlete/gear'), child: AppCard(child: Row(children: [
                  _iconBox(Icons.backpack_rounded, AppColors.warning), const SizedBox(width: 12),
                  Expanded(child: Text(gearMessage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                ])))),
                const SizedBox(height: 4),

                FadeSlideIn(delay: 400, child: SectionHeader(title: l.translate('payment'), subtitle: _monthName())),
                FadeSlideIn(delay: 450, child: AppCard(child: Row(children: [
                  _iconBox(_paymentIcon(), _paymentColor()), const SizedBox(width: 12),
                  Expanded(child: Text(l.translate('status'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
                  StatusBadge(label: _paymentLabel(), color: _paymentColor()),
                ]))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) => Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18));

  Widget _attDay(String label, String? status) {
    final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
    final icon = status == 'present' ? Icons.check_circle_rounded : status == 'absent' ? Icons.cancel_rounded : Icons.remove_circle_outline;
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22)),
    ]);
  }

  Color _paymentColor() => switch (paymentStatus) { 'paid' => AppColors.success, 'late' => AppColors.error, _ => AppColors.warning };
  IconData _paymentIcon() => switch (paymentStatus) { 'paid' => Icons.check_circle, 'late' => Icons.warning_rounded, _ => Icons.schedule };
  String _paymentLabel() { final l = AppLocalizations.of(context); return switch (paymentStatus) { 'paid' => l.translate('paid'), 'late' => l.translate('late'), 'pending' => l.translate('pending'), _ => l.translate('unknown') }; }
}
