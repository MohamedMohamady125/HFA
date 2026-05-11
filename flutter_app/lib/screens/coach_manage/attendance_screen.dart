import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const days = ['Day 1', 'Day 2', 'Day 3'];
  String selectedDay = 'Day 1';
  bool loading = true;
  List<dynamic> attendance = [];
  List<String> sessionDates = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchSessionDates();
  }

  int? get _branchId => context.read<AuthProvider>().branchId;

  Future<void> _fetchSessionDates() async {
    try {
      final res = await ApiService().get('/attendance/branch/$_branchId/session-dates');
      sessionDates = List<String>.from(res.data);
      if (sessionDates.length == 3) _fetchAttendance();
    } catch (_) {
      if (mounted) setState(() => error = 'Failed to load session dates');
    }
  }

  String _getDateForDay() {
    final index = days.indexOf(selectedDay);
    return index < sessionDates.length ? sessionDates[index] : '';
  }

  Future<void> _fetchAttendance() async {
    setState(() { loading = true; error = null; });
    try {
      final date = _getDateForDay();
      if (date.isEmpty) throw Exception('Session date not available');
      final res = await ApiService().get('/attendance/branch/$_branchId/day/$date');
      attendance = res.data;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _markAttendance(int athleteId, String status) async {
    try {
      await ApiService().post('/attendance/mark', data: {'athlete_id': athleteId, 'session_date': _getDateForDay(), 'status': status});
      _fetchAttendance();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update attendance'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_branchId == null) {
      return const Scaffold(body: Center(child: Text('No branch assigned to your account', style: TextStyle(color: Colors.red))));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFF007AFF)), onPressed: () => context.pop()),
                  const Expanded(child: Text('\u{1F3CA} Weekly Attendance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  IconButton(icon: const Icon(Icons.list, color: Color(0xFF007AFF)), onPressed: () => context.push('/coach-manage/summary')),
                ],
              ),
              const SizedBox(height: 20),

              // Day tabs
              Row(
                children: days.map((day) {
                  final isActive = selectedDay == day;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () { setState(() => selectedDay = day); _fetchAttendance(); },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFE3F2FD) : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF007AFF) : Colors.transparent, width: 2)),
                        ),
                        child: Center(child: Text(day, style: TextStyle(fontSize: 14, color: isActive ? const Color(0xFF007AFF) : const Color(0xFF555555), fontWeight: isActive ? FontWeight.w600 : FontWeight.w500))),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              if (error != null) Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500), textAlign: TextAlign.center),

              if (loading)
                const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Color(0xFF007AFF)), SizedBox(height: 12), Text('Loading attendance...', style: TextStyle(color: Color(0xFF718096)))])))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: attendance.length,
                    itemBuilder: (_, i) {
                      final item = attendance[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['athlete_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                              Row(
                                children: [
                                  _statusButton('\u{2705}', item['status'] == 'present', const Color(0xFF48BB78), () => _markAttendance(item['athlete_id'], 'present')),
                                  const SizedBox(width: 12),
                                  _statusButton('\u{274C}', item['status'] == 'absent', const Color(0xFFF56565), () => _markAttendance(item['athlete_id'], 'absent')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton(String icon, bool active, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: active ? activeColor : const Color(0xFFF0F4F8)),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
      ),
    );
  }
}
