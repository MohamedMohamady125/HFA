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
  String gearMessage = '';
  String lastThreadMessage = '';
  String? paymentStatus;
  bool loading = true;

  String _dueDateKey() { final n = DateTime.now(); return '${n.year}-${n.month.toString().padLeft(2, '0')}-01'; }
  String _monthName() => DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  void initState() { super.initState(); _fetchData(); }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final user = jsonDecode(stored);
      final dio = Dio();
      final headers = {'Authorization': 'Bearer ${user['token']}'};
      final base = ApiService.baseUrl;

      try { final r = await dio.get('$base/attendance/athlete/${user['id']}/week', options: Options(headers: headers)); attendance = r.data ?? []; } catch (_) { attendance = []; }
      try { final r = await dio.get('$base/gear/${user['branch_id']}', options: Options(headers: headers)); gearMessage = r.data?['message'] ?? 'No recent gear update.'; } catch (_) { gearMessage = 'No gear updates.'; }
      try {
        final r = await dio.get('$base/threads/branch/${user['branch_id']}', options: Options(headers: headers));
        final threads = (r.data as List).where((t) => !(t['title'] as String).toLowerCase().contains('gear')).toList();
        if (threads.isNotEmpty) {
          final p = await dio.get('$base/threads/${threads[0]['id']}/posts', options: Options(headers: headers));
          lastThreadMessage = (p.data as List).isNotEmpty ? p.data[0]['message'] ?? '' : 'No posts yet.';
        } else { lastThreadMessage = 'No threads available.'; }
      } catch (_) { lastThreadMessage = 'No threads available.'; }
      try { final r = await dio.get('$base/payments/${user['id']}/status', options: Options(headers: headers)); paymentStatus = (r.data ?? {})[_dueDateKey()] ?? 'pending'; } catch (_) { paymentStatus = 'pending'; }
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return AppLoadingScreen(message: l.translate('loading_dashboard'));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.translate('dashboard'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(DateFormat('EEEE, MMM d').format(DateTime.now()), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ]),
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.pool_rounded, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Attendance
                SectionHeader(title: l.translate('weekly_attendance')),
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(3, (i) {
                      final record = attendance.where((d) => d['day_number'] == i + 1).firstOrNull;
                      final status = record?['status'];
                      return _attendanceDay('Day ${i + 1}', status);
                    }),
                  ),
                ),
                const SizedBox(height: 8),

                // Thread
                SectionHeader(title: l.translate('latest_thread')),
                AppCard(
                  onTap: () => context.go('/athlete/threads'),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.forum_rounded, color: AppColors.info, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(lastThreadMessage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Gear
                SectionHeader(title: l.translate('gear_check')),
                AppCard(
                  onTap: () => context.go('/athlete/gear'),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.backpack_rounded, color: AppColors.warning, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(gearMessage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Payment
                SectionHeader(title: l.translate('payment'), subtitle: _monthName()),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: _paymentColor().withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_paymentIcon(), color: _paymentColor(), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(l.translate('status'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
                      StatusBadge(label: _paymentLabel(), color: _paymentColor()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _attendanceDay(String label, String? status) {
    final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
    final icon = status == 'present' ? Icons.check_circle_rounded : status == 'absent' ? Icons.cancel_rounded : Icons.remove_circle_outline;
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(status?.capitalize() ?? '\u2014', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _paymentColor() => switch (paymentStatus) { 'paid' => AppColors.success, 'late' => AppColors.error, _ => AppColors.warning };
  IconData _paymentIcon() => switch (paymentStatus) { 'paid' => Icons.check_circle, 'late' => Icons.warning_rounded, _ => Icons.schedule };
  String _paymentLabel() {
    final l = AppLocalizations.of(context);
    return switch (paymentStatus) { 'paid' => l.translate('paid'), 'late' => l.translate('late'), 'pending' => l.translate('pending'), _ => l.translate('unknown') };
  }
}

extension on String { String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}'; }
