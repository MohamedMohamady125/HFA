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
    if (loading) return AppLoadingScreen(message: l.translate('loading_summary'));
    final grouped = _group();

    return Scaffold(
      appBar: AppBar(title: Text(l.translate('attendance_summary_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: grouped.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                ...sessionDates.asMap().entries.map((d) {
                  final status = entry.value[d.value];
                  final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Icon(status == 'present' ? Icons.check_circle : status == 'absent' ? Icons.cancel : Icons.remove_circle_outline, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text('Day ${d.key + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(status ?? '\u{2014}', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                    ]),
                  );
                }),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
