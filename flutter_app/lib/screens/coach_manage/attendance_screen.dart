import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  List<String> get days => [for (int i = 1; i <= 3; i++) '${AppLocalizations.of(context).translate('day')} $i'];
  int selectedDay = 0;
  bool loading = true;
  List<dynamic> attendance = [];
  List<String> sessionDates = [];
  String? error;
  late AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fetchSessionDates();
  }

  @override
  void dispose() { _listAnim.dispose(); super.dispose(); }

  int? get _branchId => context.read<AuthProvider>().branchId;

  Future<void> _fetchSessionDates() async {
    try { final data = await OfflineRepository.getSessionDates(_branchId!); sessionDates = List<String>.from(data); if (sessionDates.length == 3) _fetchAttendance(); }
    catch (_) { if (mounted) setState(() => error = AppLocalizations.of(context).translate('failed_load_sessions')); }
  }

  Future<void> _fetchAttendance({bool silent = false}) async {
    if (!silent) setState(() { loading = true; error = null; });
    try {
      if (selectedDay >= sessionDates.length) throw Exception('No date');
      final data = await OfflineRepository.getAttendanceDay(_branchId!, sessionDates[selectedDay]);
      attendance = data;
      if (!silent) { _listAnim.reset(); _listAnim.forward(); }
    } catch (e) { error = e.toString(); }
    finally { if (mounted) setState(() => loading = false); }
  }

  void _mark(int athleteId, String status, int index) {
    // Instant local update - zero await, zero spinner
    setState(() {
      for (int i = 0; i < attendance.length; i++) {
        if (attendance[i]['athlete_id'] == athleteId) {
          attendance[i] = {...Map<String, dynamic>.from(attendance[i]), 'status': status};
          break;
        }
      }
    });
    // Fire and forget - syncs in background or queues offline
    OfflineRepository.markAttendance(athleteId, sessionDates[selectedDay], status, _branchId!);
  }

  void _msg(String msg, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.success));

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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: List.generate(3, (i) {
                final active = selectedDay == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () { setState(() => selectedDay = i); _fetchAttendance(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: active ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                      ),
                      child: Center(child: Text(days[i], style: TextStyle(fontSize: 14, color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700))),
                    ),
                  ),
                );
              }),
            ),
          ),

          if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: AppColors.error))),

          if (loading)
            const Expanded(child: ShimmerList(count: 5))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchAttendance(silent: true),
                color: AppColors.accent,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: attendance.length,
                  itemBuilder: (_, i) {
                    final item = attendance[i];
                    final id = item['athlete_id'];
                    final status = item['status'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AppCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: status == 'present' ? AppColors.success.withValues(alpha: 0.1) : status == 'absent' ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text((item['athlete_name'] ?? '?')[0].toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                color: status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item['athlete_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                            _statusBtn(Icons.check_rounded, status == 'present', AppColors.success, () => _mark(id, 'present', i)),
                            const SizedBox(width: 6),
                            _statusBtn(Icons.close_rounded, status == 'absent', AppColors.error, () => _mark(id, 'absent', i)),
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

  Widget _statusBtn(IconData icon, bool active, Color color, VoidCallback onTap) {
    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: active ? color : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Icon(icon, color: active ? Colors.white : AppColors.textTertiary, size: 20),
      ),
    );
  }
}
