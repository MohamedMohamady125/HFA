import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AthleteAttendanceScreen extends StatefulWidget {
  const AthleteAttendanceScreen({super.key});
  @override
  State<AthleteAttendanceScreen> createState() => _AthleteAttendanceScreenState();
}

class _AthleteAttendanceScreenState extends State<AthleteAttendanceScreen> {
  Map<String, String> attendanceMap = {}; // "2026-05-12" -> "present"/"absent"
  late DateTime _currentMonth;
  bool loading = true;
  int presentCount = 0;
  int absentCount = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final user = jsonDecode(stored);
      final res = await ApiService().get('/attendance/athlete/${user['id']}/history');
      attendanceMap = {};
      for (var r in (res.data as List)) {
        attendanceMap[r['date']] = r['status'];
      }
      _updateCounts();
    } catch (_) {} finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _updateCounts() {
    final monthStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    final monthEntries = attendanceMap.entries.where((e) => e.key.startsWith(monthStr));
    presentCount = monthEntries.where((e) => e.value == 'present').length;
    absentCount = monthEntries.where((e) => e.value == 'absent').length;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _updateCounts();
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _currentMonth = next;
      _updateCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const AppLoadingScreen(message: 'Loading attendance...');

    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 0=Sun

    final monthStr = '${year}-${month.toString().padLeft(2, '0')}';
    final monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('attendance')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Month navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left_rounded, size: 28)),
                Text('${monthNames[month]} $year', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right_rounded, size: 28)),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(child: _statCard(l.translate('present'), presentCount, AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _statCard(l.translate('absent'), absentCount, AppColors.error)),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar grid
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Weekday headers
                  Row(
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((d) => Expanded(
                              child: Center(child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary))),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Day cells
                  ...List.generate(((daysInMonth + firstWeekday + 6) ~/ 7), (week) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: List.generate(7, (col) {
                          final dayIndex = week * 7 + col - firstWeekday + 1;
                          if (dayIndex < 1 || dayIndex > daysInMonth) {
                            return const Expanded(child: SizedBox(height: 40));
                          }

                          final dateStr = '$monthStr-${dayIndex.toString().padLeft(2, '0')}';
                          final status = attendanceMap[dateStr];

                          Color? bgColor;
                          Color textColor = AppColors.textPrimary;
                          if (status == 'present') {
                            bgColor = AppColors.success;
                            textColor = Colors.white;
                          } else if (status == 'absent') {
                            bgColor = AppColors.error;
                            textColor = Colors.white;
                          }

                          return Expanded(
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: bgColor ?? Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: bgColor == null ? Border.all(color: AppColors.divider, width: 0.5) : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$dayIndex',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Legend
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.success, l.translate('present')),
                const SizedBox(width: 24),
                _legendDot(AppColors.error, l.translate('absent')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
