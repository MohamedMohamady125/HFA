import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});
  @override
  State<AttendanceSummaryScreen> createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  List<dynamic> athletes = [];
  bool loading = true;
  String search = '';

  @override
  void initState() {
    super.initState();
    // Cache-first: show instantly if we have saved stats (even offline).
    final branchId = context.read<AuthProvider>().branchId;
    if (branchId != null) {
      final cached = OfflineRepository.getCached('/attendance/branch/$branchId/athletes-stats');
      if (cached is List && cached.isNotEmpty) { athletes = cached; loading = false; }
    }
    _fetch();
  }

  Future<void> _fetch() async {
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final data = await OfflineRepository.getAthletesStats(
        branchId!,
        onFresh: (fresh) { if (mounted && fresh is List) setState(() => athletes = fresh); },
      );
      athletes = data;
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: ShimmerList(count: 6));

    final filtered = athletes.where((a) => (a['athlete_name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      body: Column(
        children: [
          FadeSlideIn(
            child: HeroHeader(
              title: AppLocalizations.of(context).translate('attendance_summary_title'),
              leading: HeaderIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text('${athletes.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              bottom: TextField(
                onChanged: (v) => setState(() => search = v),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).translate('search_athlete'),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.accent,
              child: filtered.isEmpty
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                      const SizedBox(height: 60),
                      athletes.isEmpty && !ConnectivityService.isOnline
                          ? EmptyState(
                              icon: Icons.wifi_off_rounded,
                              title: AppLocalizations.of(context).translate('no_connection'),
                              message: AppLocalizations.of(context).translate('offline_pull_refresh'),
                            )
                          : EmptyState(icon: Icons.people_outline_rounded, title: AppLocalizations.of(context).translate('no_athletes')),
                    ])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 20),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final a = filtered[i];
                        final rate = a['rate'] ?? 0;
                        final rateColor = rate >= 75 ? AppColors.success : rate >= 50 ? AppColors.warning : AppColors.error;

                        return FadeSlideIn(
                          delay: i * 50,
                          child: ScaleOnTap(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => _AthleteAttendanceDetail(userId: a['user_id'], athleteName: a['athlete_name']),
                            )),
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  GradientAvatar(name: a['athlete_name'] ?? '?', size: 46),
                                  const SizedBox(width: 14),
                                  // Name + stats
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(a['athlete_name'] ?? '', style: AppTypography.titleMedium),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      _miniStat('${a['present']}', AppColors.success),
                                      const SizedBox(width: 6),
                                      _miniStat('${a['absent']}', AppColors.error),
                                      const SizedBox(width: 6),
                                      Flexible(child: Text('${a['total']} ${AppLocalizations.of(context).translate('of_sessions')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary))),
                                    ]),
                                  ])),
                                  // Rate badge
                                  StatusBadge(label: '$rate%', color: rateColor),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 22),
                                ],
                              ),
                            ),
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

  Widget _miniStat(String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(color == AppColors.success ? Icons.check_rounded : Icons.close_rounded, size: 12, color: color),
        const SizedBox(width: 2),
        Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ATHLETE DETAIL - Monthly Calendar (Coach view)
// ═══════════════════════════════════════════════════════════
class _AthleteAttendanceDetail extends StatefulWidget {
  final int userId;
  final String athleteName;
  const _AthleteAttendanceDetail({required this.userId, required this.athleteName});

  @override
  State<_AthleteAttendanceDetail> createState() => _AthleteAttendanceDetailState();
}

class _AthleteAttendanceDetailState extends State<_AthleteAttendanceDetail> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, String> _attendanceMap = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetchMonth(); }

  Map<String, String> _toMap(List data) =>
      { for (var r in data) r['date'].toString(): r['status']?.toString() ?? '' };

  Future<void> _fetchMonth() async {
    setState(() => _loading = true);
    final month = _currentMonth;
    try {
      final data = await OfflineRepository.getAttendanceMonth(
        widget.userId, month.year, month.month,
        onFresh: (fresh) { if (mounted && fresh is List && _currentMonth == month) setState(() => _attendanceMap = _toMap(fresh)); },
      );
      _attendanceMap = _toMap(data);
    } catch (_) { _attendanceMap = {}; }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _prevMonth() { setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)); _fetchMonth(); }
  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() => _currentMonth = next);
    _fetchMonth();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;
    final presentCount = _attendanceMap.values.where((s) => s == 'present').length;
    final absentCount = _attendanceMap.values.where((s) => s == 'absent').length;
    final total = presentCount + absentCount;
    final rate = total > 0 ? (presentCount / total * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.athleteName)),
      body: Column(
        children: [
          // Month nav
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              _navBtn(Icons.chevron_left_rounded, _prevMonth),
              Expanded(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(DateFormat('MMMM yyyy', AppLocalizations.of(context).locale.languageCode).format(_currentMonth), key: ValueKey(_currentMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
              )),
              _navBtn(Icons.chevron_right_rounded, isCurrentMonth ? null : _nextMonth),
            ]),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: StatCard(value: '$presentCount', label: AppLocalizations.of(context).translate('present'), icon: Icons.check_circle_rounded, color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(value: '$absentCount', label: AppLocalizations.of(context).translate('absent'), icon: Icons.cancel_rounded, color: AppColors.error)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(value: '$rate%', label: AppLocalizations.of(context).translate('rate'), icon: Icons.insights_rounded, color: AppColors.accent)),
            ]),
          ),
          const SizedBox(height: 16),

          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Jan 5, 2025 is a Sunday
                for (int i = 0; i < 7; i++)
                  Expanded(child: Center(child: Text(
                    DateFormat.E(AppLocalizations.of(context).locale.languageCode).format(DateTime(2025, 1, 5 + i)),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                  )))]
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
          else
            _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) { cells.add(const SizedBox()); }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final status = _attendanceMap[dateStr];
      final isToday = date == today;
      final isFuture = date.isAfter(today);

      Color? bgColor;
      Color textColor = AppColors.textPrimary;
      IconData? icon;

      if (status == 'present') { bgColor = AppColors.success; textColor = Colors.white; icon = Icons.check_rounded; }
      else if (status == 'absent') { bgColor = AppColors.error; textColor = Colors.white; icon = Icons.close_rounded; }
      else if (isFuture) { textColor = AppColors.textTertiary; }

      cells.add(AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor?.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: AppColors.accent, width: 2.5) : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$day', style: TextStyle(fontSize: 14, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: bgColor != null ? textColor : textColor)),
          if (icon != null) Icon(icon, size: 14, color: textColor),
        ]),
      ));
    }

    return GridView.count(crossAxisCount: 7, padding: const EdgeInsets.symmetric(horizontal: 12), childAspectRatio: 1, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: cells);
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: onTap != null ? AppColors.surfaceLight : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: onTap != null ? AppColors.textPrimary : AppColors.textTertiary, size: 24)));
  }

}
