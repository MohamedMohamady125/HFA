import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AthleteAttendanceScreen extends StatefulWidget {
  const AthleteAttendanceScreen({super.key});
  @override
  State<AthleteAttendanceScreen> createState() => _AthleteAttendanceScreenState();
}

class _AthleteAttendanceScreenState extends State<AthleteAttendanceScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, String> _attendanceMap = {};
  bool _loading = true;
  int? _userId;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('authUser');
    if (stored != null) _userId = jsonDecode(stored)['id'];
    _fetchMonth();
  }

  void _applyMonth(dynamic data) {
    if (data is List) {
      _attendanceMap = { for (var r in data) r['date'].toString(): r['status']?.toString() ?? '' };
    } else {
      _attendanceMap = {};
    }
  }

  Future<void> _fetchMonth() async {
    if (_userId == null) return;
    final month = _currentMonth; // guard against month changing mid-flight

    // 1. Instant cache read — no spinner if we already have this month
    final cached = OfflineRepository.getCached('/attendance/athlete/$_userId/month/${month.year}/${month.month}');
    if (cached is List) {
      _applyMonth(cached);
      if (mounted) setState(() => _loading = false);
    } else {
      if (mounted) setState(() { _attendanceMap = {}; _loading = true; });
    }

    // 2. Cache-first fetch with background refresh
    final data = await OfflineRepository.getAttendanceMonth(
      _userId!, month.year, month.month,
      onFresh: (fresh) {
        if (mounted && month == _currentMonth) setState(() => _applyMonth(fresh));
      },
    );
    if (mounted && month == _currentMonth) {
      setState(() { _applyMonth(data); _loading = false; });
    }
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
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

    final presentCount = _attendanceMap.values.where((s) => s == 'present').length;
    final absentCount = _attendanceMap.values.where((s) => s == 'absent').length;
    final total = presentCount + absentCount;
    final rate = total > 0 ? (presentCount / total * 100).round() : 0;

    return Scaffold(
      body: Column(
        children: [
          FadeSlideIn(
            child: HeroHeader(
              title: l.translate('attendance'),
              subtitle: DateFormat('MMMM yyyy', l.locale.languageCode).format(_currentMonth),
              leading: HeaderIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
              bottom: Row(children: [
                StatChip(icon: Icons.check_circle_rounded, value: '$presentCount', label: l.translate('present')),
                const SizedBox(width: AppSpacing.sm),
                StatChip(icon: Icons.cancel_rounded, value: '$absentCount', label: l.translate('absent')),
                const SizedBox(width: AppSpacing.sm),
                StatChip(icon: Icons.donut_large_rounded, value: '$rate%', label: l.translate('rate')),
              ]),
            ),
          ),

          // Month navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Row(children: [
              _navBtn(Icons.chevron_left_rounded, _prevMonth),
              Expanded(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(DateFormat('MMMM yyyy', l.locale.languageCode).format(_currentMonth), key: ValueKey(_currentMonth),
                  style: AppTypography.titleLarge, textAlign: TextAlign.center),
              )),
              _navBtn(Icons.chevron_right_rounded, isCurrentMonth ? null : _nextMonth),
            ]),
          ),

          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [for (int i = 0; i < 7; i++) Expanded(child: Center(child: Text(
                DateFormat.E(l.locale.languageCode).format(DateTime(2025, 1, 5 + i)),
                style: AppTypography.overline,
              )))],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Calendar
          if (_loading)
            const Expanded(child: ShimmerList(count: 4))
          else if (_attendanceMap.isEmpty && !ConnectivityService.isOnline)
            Expanded(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: l.translate('no_connection'),
                message: l.translate('no_connection_data'),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: FadeSlideIn(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: _buildCalendar(),
                    ),
                  ),
                ),
              ),
            ),
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
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final status = _attendanceMap[dateStr];
      final isToday = date == today;
      final isFuture = date.isAfter(today);

      Color? bgColor;
      Color textColor = AppColors.textPrimary;
      IconData? icon;

      if (status == 'present') {
        bgColor = AppColors.success;
        textColor = Colors.white;
        icon = Icons.check_rounded;
      } else if (status == 'absent') {
        bgColor = AppColors.error;
        textColor = Colors.white;
        icon = Icons.close_rounded;
      } else if (isFuture) {
        textColor = AppColors.textTertiary;
      }

      cells.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bgColor?.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isToday ? Border.all(color: AppColors.accent, width: 2.5) : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$day', style: TextStyle(fontSize: 14, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: textColor)),
            if (icon != null) Icon(icon, size: 14, color: textColor),
          ]),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      padding: EdgeInsets.zero,
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: cells,
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap != null ? AppColors.surfaceLight : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          width: 48, height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: onTap != null ? AppColors.textPrimary : AppColors.textTertiary, size: 24),
        ),
      ),
    );
  }
}
