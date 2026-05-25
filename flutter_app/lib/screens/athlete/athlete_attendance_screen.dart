import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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

  Future<void> _fetchMonth() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService().get('/attendance/athlete/$_userId/month/${_currentMonth.year}/${_currentMonth.month}');
      final data = res.data as List;
      _attendanceMap = { for (var r in data) r['date'].toString(): r['status']?.toString() ?? '' };
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
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // Month navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              _navBtn(Icons.chevron_left_rounded, _prevMonth),
              Expanded(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(DateFormat('MMMM yyyy').format(_currentMonth), key: ValueKey(_currentMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
              )),
              _navBtn(Icons.chevron_right_rounded, isCurrentMonth ? null : _nextMonth),
            ]),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _statCard('Present', '$presentCount', AppColors.success),
              const SizedBox(width: 10),
              _statCard('Absent', '$absentCount', AppColors.error),
              const SizedBox(width: 10),
              _statCard('Rate', '$rate%', AppColors.accent),
            ]),
          ),
          const SizedBox(height: 16),

          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)))))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar
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
    for (int i = 0; i < startWeekday; i++) cells.add(const SizedBox());

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
            borderRadius: BorderRadius.circular(10),
            border: isToday ? Border.all(color: AppColors.accent, width: 2.5) : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$day', style: TextStyle(fontSize: 14, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: bgColor != null ? textColor : textColor)),
            if (icon != null) Icon(icon, size: 14, color: textColor),
          ]),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: cells,
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: onTap != null ? AppColors.surfaceLight : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: onTap != null ? AppColors.textPrimary : AppColors.textTertiary, size: 24),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}
