import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});
  @override
  State<AttendanceSummaryScreen> createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  List<dynamic> records = [];
  List<String> sessionDates = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _fetchSummary(); }

  Future<void> _fetchSummary() async {
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final results = await Future.wait([
        ApiService().get('/attendance/branch/$branchId/summary'),
        ApiService().get('/attendance/branch/$branchId/session-dates'),
      ]);
      records = results[0].data['records'] ?? [];
      sessionDates = List<String>.from(results[1].data ?? []);
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Map<String, Map<String, String>> _group() {
    final g = <String, Map<String, String>>{};
    for (var r in records) { g.putIfAbsent(r['athlete_name'], () => {}); g[r['athlete_name']]![r['session_date']] = r['status']; }
    return g;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 5));
    final grouped = _group();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('attendance_summary_title')),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('${grouped.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ))),
        ],
      ),
      body: grouped.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle),
                child: const Icon(Icons.assessment_outlined, size: 40, color: AppColors.textTertiary)),
              const SizedBox(height: 16),
              const Text('No attendance data', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            ]))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: grouped.length,
              itemBuilder: (_, i) {
                final entry = grouped.entries.elementAt(i);
                return FadeSlideIn(
                  delay: i * 50,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(entry.key[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                            ),
                            const SizedBox(width: 12),
                            Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ]),
                          const SizedBox(height: 14),
                          ...sessionDates.asMap().entries.map((d) {
                            final status = entry.value[d.value];
                            final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                                child: Row(children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Icon(status == 'present' ? Icons.check_rounded : status == 'absent' ? Icons.close_rounded : Icons.remove_rounded, color: color, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Day ${d.key + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                  const Spacer(),
                                  Text(status ?? '\u{2014}', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
