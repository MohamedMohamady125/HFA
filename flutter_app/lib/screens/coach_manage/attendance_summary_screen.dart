import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final results = await Future.wait([
        ApiService().get('/attendance/branch/$branchId/summary'),
        ApiService().get('/attendance/branch/$branchId/session-dates'),
      ]);
      records = results[0].data['records'] ?? [];
      sessionDates = List<String>.from(results[1].data ?? []);
    } catch (e) {
      debugPrint('Failed to load summary: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, Map<String, String>> _groupRecords() {
    final grouped = <String, Map<String, String>>{};
    for (var row in records) {
      final name = row['athlete_name'] as String;
      grouped.putIfAbsent(name, () => {});
      grouped[name]![row['session_date']] = row['status'];
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Color(0xFF007AFF)), SizedBox(height: 10), Text('Loading summary...')])));
    }

    final grouped = _groupRecords();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('\u{1F4CA} Attendance Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...grouped.entries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A202C))),
                      const SizedBox(height: 8),
                      ...sessionDates.asMap().entries.map((d) => Text('Day ${d.key + 1} (${d.value}): ${entry.value[d.value] ?? '\u{2014}'}', style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
