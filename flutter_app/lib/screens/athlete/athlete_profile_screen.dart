import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class AthleteProfileScreen extends StatefulWidget {
  const AthleteProfileScreen({super.key});
  @override
  State<AthleteProfileScreen> createState() => _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends State<AthleteProfileScreen> {
  Map<String, dynamic>? user;
  List<dynamic> attendance = [];
  String branchName = '';
  List<String> labels = ['Day 1', 'Day 2', 'Day 3'];
  Map<String, TextEditingController> measurementControllers = {};
  bool editable = true;
  List<Map<String, TextEditingController>> eventControllers = [];
  bool eventsEditable = true;

  final _measurementKeys = ['height', 'weight', 'arm', 'leg', 'fat', 'muscle'];
  final _measurementLabels = {
    'height': 'Height (cm)', 'weight': 'Weight (kg)', 'arm': 'Arm Length (cm)',
    'leg': 'Leg Length', 'fat': 'Fat Percentage %', 'muscle': 'Muscle Percentage %',
  };

  @override
  void initState() {
    super.initState();
    for (var k in _measurementKeys) {
      measurementControllers[k] = TextEditingController();
    }
    eventControllers.add({'name': TextEditingController(), 'time': TextEditingController()});
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('authUser');
    if (stored == null) return;
    final parsed = jsonDecode(stored);
    user = parsed;
    final headers = {'Authorization': 'Bearer ${parsed['token']}'};
    final dio = Dio();
    const baseUrl = '${ApiService.baseUrl}';

    try {
      final results = await Future.wait([
        dio.get('$baseUrl/attendance/athlete/${parsed['id']}/week', options: Options(headers: headers)),
        dio.get('$baseUrl/branches/${parsed['branch_id']}', options: Options(headers: headers)),
        dio.get('$baseUrl/attendance/branch/${parsed['branch_id']}/session-dates', options: Options(headers: headers)),
        dio.get('$baseUrl/athlete/measurements', options: Options(headers: headers)),
      ]);

      attendance = results[0].data;
      branchName = results[1].data['name'] ?? '';
      if (results[2].data is List) {
        labels = List.generate((results[2].data as List).length, (i) => 'Day ${i + 1}');
      }

      final mData = results[3].data is List ? (results[3].data as List).firstOrNull : results[3].data;
      if (mData != null) {
        for (var k in _measurementKeys) {
          measurementControllers[k]!.text = mData[k]?.toString() ?? '';
        }
        editable = false;
      }

      // Try events
      try {
        final eventsRes = await dio.get('$baseUrl/athlete/performance-logs', options: Options(headers: headers));
        if (eventsRes.data is List && (eventsRes.data as List).isNotEmpty) {
          eventControllers = (eventsRes.data as List).map((e) => {
            'name': TextEditingController(text: e['event_name'] ?? ''),
            'time': TextEditingController(text: e['result_time']?.toString() ?? ''),
          }).toList();
          eventsEditable = false;
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveMeasurements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final parsed = jsonDecode(stored);
      final dio = Dio();

      final data = <String, double>{};
      for (var k in _measurementKeys) {
        data[k] = double.tryParse(measurementControllers[k]!.text) ?? 0;
      }

      await dio.post('${ApiService.baseUrl}/athlete/measurements', data: data, options: Options(headers: {'Authorization': 'Bearer ${parsed['token']}'}));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurements saved!'), backgroundColor: Colors.green));
        setState(() => editable = false);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save measurements'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final parsed = jsonDecode(stored);
      final dio = Dio();
      final headers = {'Authorization': 'Bearer ${parsed['token']}'};

      final validEvents = eventControllers.where((e) => e['name']!.text.isNotEmpty && e['time']!.text.isNotEmpty).toList();
      if (validEvents.isEmpty) return;

      try { await dio.delete('${ApiService.baseUrl}/athlete/performance-logs', options: Options(headers: headers)); } catch (_) {}

      for (var e in validEvents) {
        await dio.post('${ApiService.baseUrl}/athlete/performance-log', data: {
          'meet_name': 'Top Swim Event',
          'meet_date': DateTime.now().toIso8601String().split('T')[0],
          'event_name': e['name']!.text,
          'result_time': double.tryParse(e['time']!.text) ?? 0,
        }, options: Options(headers: headers));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Events saved!'), backgroundColor: Colors.green));
        setState(() => eventsEditable = false);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save events'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\u{1F389} Welcome back, ${user!['name']}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('\u{1F3E2} Branch: $branchName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF555555))),
              const SizedBox(height: 20),

              // Attendance
              _buildSection('\u{1F3C6} Attendance Tracker', child: Wrap(
                spacing: 10, runSpacing: 10,
                children: labels.asMap().entries.map((e) {
                  final record = attendance.where((r) => r['day_number'] == e.key + 1).firstOrNull;
                  final status = record?['status'];
                  return Column(
                    children: [
                      Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Icon(
                        status == 'present' ? Icons.check_circle : status == 'absent' ? Icons.cancel : Icons.remove_circle_outline,
                        color: status == 'present' ? Colors.green : status == 'absent' ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                      Text(status?.toString().capitalize() ?? '\u{2014}', style: TextStyle(color: status == 'present' ? Colors.green : status == 'absent' ? Colors.red : Colors.grey, fontSize: 12)),
                    ],
                  );
                }).toList(),
              )),

              // Measurements
              _buildSection('\u{1F4CF} Measurements', child: Column(
                children: [
                  ..._measurementKeys.map((k) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_measurementLabels[k]!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: measurementControllers[k],
                          keyboardType: TextInputType.number,
                          enabled: editable,
                          decoration: InputDecoration(filled: true, fillColor: const Color(0xFFE0F2F1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        ),
                      ],
                    ),
                  )),
                  ElevatedButton(onPressed: _saveMeasurements, child: const Text('Save Measurements')),
                  if (!editable) TextButton(onPressed: () => setState(() => editable = true), child: const Text('Edit Measurements', style: TextStyle(color: Colors.white))),
                ],
              )),

              // Swim Events
              _buildSection('\u{1F3CA} Top Swim Events', child: Column(
                children: [
                  ...eventControllers.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: e.value['name'], enabled: eventsEditable, decoration: InputDecoration(hintText: 'Event Name', filled: true, fillColor: const Color(0xFFE0F2F1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none)))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: e.value['time'], enabled: eventsEditable, decoration: InputDecoration(hintText: 'Time', filled: true, fillColor: const Color(0xFFE0F2F1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none)))),
                      ],
                    ),
                  )),
                  if (eventControllers.length < 5 && eventsEditable)
                    TextButton(onPressed: () => setState(() => eventControllers.add({'name': TextEditingController(), 'time': TextEditingController()})), child: const Text('Add Event', style: TextStyle(color: Colors.white))),
                  ElevatedButton(onPressed: _saveEvents, child: const Text('Save Events')),
                  if (!eventsEditable) TextButton(onPressed: () => setState(() => eventsEditable = true), child: const Text('Edit Events', style: TextStyle(color: Colors.white))),
                ],
              )),

              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/guest-home');
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF3399FF), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var c in measurementControllers.values) c.dispose();
    for (var e in eventControllers) {
      e['name']?.dispose();
      e['time']?.dispose();
    }
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
