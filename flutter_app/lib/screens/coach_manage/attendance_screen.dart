import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const days = ['Day 1', 'Day 2', 'Day 3'];
  int selectedDay = 0;
  bool loading = true;
  List<dynamic> attendance = [];
  List<String> sessionDates = [];
  String? error;

  @override
  void initState() { super.initState(); _fetchSessionDates(); }

  int? get _branchId => context.read<AuthProvider>().branchId;

  Future<void> _fetchSessionDates() async {
    try { final res = await ApiService().get('/attendance/branch/$_branchId/session-dates'); sessionDates = List<String>.from(res.data); if (sessionDates.length == 3) _fetchAttendance(); }
    catch (_) { if (mounted) setState(() => error = 'Failed to load session dates'); }
  }

  Future<void> _fetchAttendance() async {
    setState(() { loading = true; error = null; });
    try {
      if (selectedDay >= sessionDates.length) throw Exception('No date');
      final res = await ApiService().get('/attendance/branch/$_branchId/day/${sessionDates[selectedDay]}');
      attendance = res.data;
    } catch (e) { error = e.toString(); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _mark(int athleteId, String status) async {
    try { await ApiService().post('/attendance/mark', data: {'athlete_id': athleteId, 'session_date': sessionDates[selectedDay], 'status': status}); _fetchAttendance(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_branchId == null) return Scaffold(body: Center(child: Text(l.translate('no_branch'))));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('weekly_attendance_title')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.bar_chart_rounded, color: AppColors.accent), onPressed: () => context.push('/coach-manage/summary'))],
      ),
      body: Column(
        children: [
          // Day tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: List.generate(3, (i) {
                final active = selectedDay == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () { setState(() => selectedDay = i); _fetchAttendance(); },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(days[i], style: TextStyle(fontSize: 14, color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600))),
                    ),
                  ),
                );
              }),
            ),
          ),

          if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: AppColors.error))),

          if (loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: attendance.length,
                itemBuilder: (_, i) {
                  final item = attendance[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item['athlete_name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                          _statusBtn(Icons.check_rounded, item['status'] == 'present', AppColors.success, () => _mark(item['athlete_id'], 'present')),
                          const SizedBox(width: 10),
                          _statusBtn(Icons.close_rounded, item['status'] == 'absent', AppColors.error, () => _mark(item['athlete_id'], 'absent')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBtn(IconData icon, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: active ? color : AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: active ? Colors.white : AppColors.textTertiary, size: 22),
      ),
    );
  }
}
