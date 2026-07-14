import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../widgets/app_feedback.dart';
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
  // Show the "saved offline" notice at most once per screen session.
  bool _queuedNoticeShown = false;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    // Cache-first: populate synchronously so there's no shimmer when cached.
    final bId = context.read<AuthProvider>().branchId;
    if (bId != null) {
      final cachedDates = OfflineRepository.getCached('/attendance/branch/$bId/session-dates');
      if (cachedDates is List) {
        sessionDates = List<String>.from(cachedDates);
        if (sessionDates.isNotEmpty) {
          final cachedDay = OfflineRepository.getCached('/attendance/branch/$bId/day/${sessionDates[0]}');
          if (cachedDay is List) { attendance = cachedDay; loading = false; }
        }
      }
    }
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
    if (!silent && attendance.isEmpty) setState(() { loading = true; error = null; });
    try {
      if (selectedDay >= sessionDates.length) throw Exception('No date');
      final day = sessionDates[selectedDay];
      final data = await OfflineRepository.getAttendanceDay(
        _branchId!, day,
        onFresh: (fresh) {
          if (mounted && fresh is List && selectedDay < sessionDates.length && sessionDates[selectedDay] == day) {
            setState(() => attendance = fresh);
          }
        },
      );
      attendance = data;
      error = null;
      if (!silent) { _listAnim.reset(); _listAnim.forward(); }
    } catch (e) { error = e.toString(); }
    finally { if (mounted) setState(() => loading = false); }
  }

  void _mark(int athleteId, String status, int index) {
    HapticFeedback.lightImpact();
    final sessionDate = sessionDates[selectedDay];
    String? prevStatus;
    // Instant local update - zero await, zero spinner
    setState(() {
      for (int i = 0; i < attendance.length; i++) {
        if (attendance[i]['athlete_id'] == athleteId) {
          prevStatus = attendance[i]['status']?.toString();
          attendance[i] = {...Map<String, dynamic>.from(attendance[i]), 'status': status};
          break;
        }
      }
    });
    // Sync in background; queue offline. Revert only on a real server rejection.
    () async {
      try {
        final r = await OfflineRepository.markAttendance(athleteId, sessionDate, status, _branchId!);
        if (!mounted) return;
        if (!r.synced && !_queuedNoticeShown) {
          _queuedNoticeShown = true;
          AppFeedback.showQueued(context);
        }
      } catch (e) {
        if (!mounted) return;
        AppFeedback.showError(context, e);
        setState(() {
          for (int i = 0; i < attendance.length; i++) {
            if (attendance[i]['athlete_id'] == athleteId) {
              attendance[i] = {...Map<String, dynamic>.from(attendance[i]), 'status': prevStatus};
              break;
            }
          }
        });
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_branchId == null) return Scaffold(body: Center(child: Text(l.translate('no_branch'))));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: l.translate('weekly_attendance_title'),
                leading: HeaderIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                trailing: HeaderIconButton(icon: Icons.bar_chart_rounded, onTap: () => context.push('/coach-manage/summary')),
                bottom: Row(
                  children: List.generate(3, (i) {
                    final active = selectedDay == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => selectedDay = i); _fetchAttendance(); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))] : null,
                          ),
                          child: Center(child: Text(days[i], style: TextStyle(fontSize: 14, color: active ? AppColors.primary : Colors.white, fontWeight: FontWeight.w800))),
                        ),
                      ),
                    );
                  }),
                ),
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
                  child: attendance.isEmpty
                      ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                          const SizedBox(height: 60),
                          !ConnectivityService.isOnline
                              ? EmptyState(
                                  icon: Icons.wifi_off_rounded,
                                  title: l.translate('no_connection'),
                                  message: l.translate('offline_pull_refresh'),
                                )
                              : EmptyState(icon: Icons.fact_check_outlined, title: l.translate('no_athletes')),
                        ])
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 20),
                          itemCount: attendance.length,
                          itemBuilder: (_, i) {
                            final item = attendance[i];
                            final id = item['athlete_id'];
                            final status = item['status'];
                            final statusColor = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : null;

                            return AppCard(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  GradientAvatar(
                                    name: item['athlete_name'] ?? '?',
                                    size: 40,
                                    colors: statusColor != null ? [statusColor, statusColor.withValues(alpha: 0.7)] : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(item['athlete_name'] ?? '', style: AppTypography.titleMedium),
                                    if (statusColor != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: StatusBadge(label: l.translate(status), color: statusColor),
                                      ),
                                  ])),
                                  _statusBtn(Icons.check_rounded, status == 'present', AppColors.success, () => _mark(id, 'present', i)),
                                  const SizedBox(width: 8),
                                  _statusBtn(Icons.close_rounded, status == 'absent', AppColors.error, () => _mark(id, 'absent', i)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(IconData icon, bool active, Color color, VoidCallback onTap) {
    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: active ? color : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: active ? null : Border.all(color: AppColors.divider),
          boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Icon(icon, color: active ? Colors.white : AppColors.textTertiary, size: 22),
      ),
    );
  }
}
