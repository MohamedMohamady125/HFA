import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AthleteHomeScreen extends StatefulWidget {
  const AthleteHomeScreen({super.key});
  @override
  State<AthleteHomeScreen> createState() => _AthleteHomeScreenState();
}

class _AthleteHomeScreenState extends State<AthleteHomeScreen> {
  List<dynamic> attendance = [];
  String gearMessage = 'Loading...';
  String lastThreadMessage = 'Loading...';
  String? paymentStatus;
  bool loading = true;

  String _getCurrentDueDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  String _getCurrentMonthName() {
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final user = jsonDecode(stored);
      final dio = Dio();
      final headers = {'Authorization': 'Bearer ${user['token']}'};
      const baseUrl = ApiService.baseUrl;

      final athleteRes = await dio.get('$baseUrl/athletes/user/${user['id']}', options: Options(headers: headers));
      final branchId = user['branch_id'];

      // Attendance
      try {
        final attRes = await dio.get('$baseUrl/attendance/athlete/${user['id']}/week', options: Options(headers: headers));
        attendance = attRes.data ?? [];
      } catch (_) {
        attendance = [];
      }

      // Gear
      final gearRes = await dio.get('$baseUrl/gear/$branchId', options: Options(headers: headers));
      gearMessage = gearRes.data?['message'] ?? 'No recent gear update.';

      // Threads
      final threadsRes = await dio.get('$baseUrl/threads/branch/$branchId', options: Options(headers: headers));
      final threads = (threadsRes.data as List).where((t) => !(t['title'] as String).toLowerCase().contains('gear')).toList();
      if (threads.isNotEmpty) {
        final postsRes = await dio.get('$baseUrl/threads/${threads[0]['id']}/posts', options: Options(headers: headers));
        final posts = postsRes.data as List;
        lastThreadMessage = posts.isNotEmpty ? (posts[0]['message'] ?? 'No posts yet.') : 'No posts yet.';
      } else {
        lastThreadMessage = 'No threads available.';
      }

      // Payment
      final payRes = await dio.get('$baseUrl/payments/${user['id']}/status', options: Options(headers: headers));
      final payData = payRes.data ?? {};
      paymentStatus = payData[_getCurrentDueDateKey()] ?? 'pending';
    } catch (e) {
      debugPrint('Error fetching home data: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _getStatusIcon(String? status) {
    switch (status) {
      case 'present': return '\u{2705}';
      case 'absent': return '\u{274C}';
      case 'excused': return '\u{1F7E1}';
      default: return '\u{2014}';
    }
  }

  String _getPaymentIcon(String? status) {
    switch (status) {
      case 'paid': return '\u{2705}';
      case 'late': return '\u{26A0}\u{FE0F}';
      case 'pending': return '\u{23F3}';
      default: return '\u{274C}';
    }
  }

  String _getPaymentLabel(String? status) {
    switch (status) {
      case 'paid': return 'Paid';
      case 'late': return 'Late';
      case 'pending': return 'Pending';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF3399FF),
        body: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Color(0xFF3399FF)),
                SizedBox(height: 16),
                Text('Loading...', style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
        child: Column(
          children: [
            const Text('Dashboard', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF00796B))),
            const SizedBox(height: 8),
            Text(DateFormat('M/d/yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 16, color: Color(0xFF555555), fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),

            // Weekly Attendance
            _buildCard('\u{1F4C6} Weekly Attendance', children: [
              if (attendance.isEmpty)
                _buildRow('No attendance data available', '')
              else
                for (int i = 0; i < 3; i++)
                  _buildRow('Day ${i + 1}', _getStatusIcon(attendance.where((d) => d['day_number'] == i + 1).firstOrNull?['status'])),
            ]),

            // Latest Thread
            GestureDetector(
              onTap: () => context.go('/athlete/threads'),
              child: _buildCard('\u{1F4AC} Latest Thread', children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFD6ECFF), borderRadius: BorderRadius.circular(12)),
                  child: Text(lastThreadMessage, style: const TextStyle(fontSize: 15, color: Color(0xFF37474F), height: 1.47)),
                ),
              ]),
            ),

            // Gear Check
            GestureDetector(
              onTap: () => context.go('/athlete/gear'),
              child: _buildCard('\u{1F392} Gear Check', children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFD0F0FF), borderRadius: BorderRadius.circular(12)),
                  child: Text(gearMessage, style: const TextStyle(fontSize: 15, color: Color(0xFF37474F), height: 1.47)),
                ),
              ]),
            ),

            // Payment
            _buildCard('\u{1F4B0} Payment \u{2013} ${_getCurrentMonthName()}', children: [
              _buildRow('Status', '${_getPaymentIcon(paymentStatus)} ${_getPaymentLabel(paymentStatus)}',
                  bgColor: const Color(0xFFF0F9FF)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF3399FF), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String status, {Color bgColor = const Color(0xFFCCE5FF)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF37474F))),
          Text(status, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
