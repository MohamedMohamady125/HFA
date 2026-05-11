import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
  Map<String, TextEditingController> mCtrl = {};
  bool editable = true;
  List<Map<String, TextEditingController>> eventCtrl = [];
  bool eventsEditable = true;

  final _mKeys = ['height', 'weight', 'arm', 'leg', 'fat', 'muscle'];
  final _mLabels = {'height': 'Height (cm)', 'weight': 'Weight (kg)', 'arm': 'Arm (cm)', 'leg': 'Leg (cm)', 'fat': 'Fat %', 'muscle': 'Muscle %'};

  @override
  void initState() {
    super.initState();
    for (var k in _mKeys) mCtrl[k] = TextEditingController();
    eventCtrl.add({'name': TextEditingController(), 'time': TextEditingController()});
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('authUser');
    if (stored == null) return;
    final parsed = jsonDecode(stored);
    user = parsed;
    final h = {'Authorization': 'Bearer ${parsed['token']}'};
    final dio = Dio();
    final base = ApiService.baseUrl;

    try {
      final results = await Future.wait([
        dio.get('$base/attendance/athlete/${parsed['id']}/week', options: Options(headers: h)),
        dio.get('$base/branches/${parsed['branch_id']}', options: Options(headers: h)),
        dio.get('$base/attendance/branch/${parsed['branch_id']}/session-dates', options: Options(headers: h)),
        dio.get('$base/athlete/measurements', options: Options(headers: h)),
      ]);
      attendance = results[0].data;
      branchName = results[1].data['name'] ?? '';
      if (results[2].data is List) labels = List.generate((results[2].data as List).length, (i) => 'Day ${i + 1}');
      final mData = results[3].data is List ? (results[3].data as List).firstOrNull : results[3].data;
      if (mData != null) { for (var k in _mKeys) mCtrl[k]!.text = mData[k]?.toString() ?? ''; editable = false; }
      try {
        final evts = await dio.get('$base/athlete/performance-logs', options: Options(headers: h));
        if (evts.data is List && (evts.data as List).isNotEmpty) {
          eventCtrl = (evts.data as List).map((e) => {'name': TextEditingController(text: e['event_name'] ?? ''), 'time': TextEditingController(text: e['result_time']?.toString() ?? '')}).toList();
          eventsEditable = false;
        }
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _saveMeasurements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parsed = jsonDecode(prefs.getString('authUser')!);
      final data = <String, double>{};
      for (var k in _mKeys) data[k] = double.tryParse(mCtrl[k]!.text) ?? 0;
      await Dio().post('${ApiService.baseUrl}/athlete/measurements', data: data, options: Options(headers: {'Authorization': 'Bearer ${parsed['token']}'}));
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurements saved!'), backgroundColor: AppColors.success)); setState(() => editable = false); }
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save'), backgroundColor: AppColors.error)); }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parsed = jsonDecode(prefs.getString('authUser')!);
      final h = {'Authorization': 'Bearer ${parsed['token']}'};
      final dio = Dio();
      final base = ApiService.baseUrl;
      final valid = eventCtrl.where((e) => e['name']!.text.isNotEmpty && e['time']!.text.isNotEmpty).toList();
      if (valid.isEmpty) return;
      try { await dio.delete('$base/athlete/performance-logs', options: Options(headers: h)); } catch (_) {}
      for (var e in valid) {
        await dio.post('$base/athlete/performance-log', data: {'meet_name': 'Top Swim Event', 'meet_date': DateTime.now().toIso8601String().split('T')[0], 'event_name': e['name']!.text, 'result_time': double.tryParse(e['time']!.text) ?? 0}, options: Options(headers: h));
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Events saved!'), backgroundColor: AppColors.success)); setState(() => eventsEditable = false); }
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save'), backgroundColor: AppColors.error)); }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const AppLoadingScreen();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: AppColors.accent, child: Text((user!['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user!['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.location_on_rounded, size: 14, color: AppColors.accent), const SizedBox(width: 4), Text(branchName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))]),
                      ]),
                    ),
                  ],
                ),
              ),

              // Attendance
              const SizedBox(height: 8),
              const SectionHeader(title: 'Attendance'),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: labels.asMap().entries.map((e) {
                    final record = attendance.where((r) => r['day_number'] == e.key + 1).firstOrNull;
                    final status = record?['status'];
                    final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
                    return Column(children: [
                      Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Icon(status == 'present' ? Icons.check_circle_rounded : status == 'absent' ? Icons.cancel_rounded : Icons.remove_circle_outline, color: color, size: 28),
                    ]);
                  }).toList(),
                ),
              ),

              // Measurements
              const SizedBox(height: 8),
              SectionHeader(title: 'Measurements', trailing: editable ? null : TextButton(onPressed: () => setState(() => editable = true), child: const Text('Edit', style: TextStyle(color: AppColors.accent)))),
              AppCard(
                child: Column(
                  children: [
                    ..._mKeys.map((k) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        SizedBox(width: 100, child: Text(_mLabels[k]!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
                        Expanded(child: TextField(controller: mCtrl[k], keyboardType: TextInputType.number, enabled: editable, style: const TextStyle(fontSize: 14), decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true))),
                      ]),
                    )),
                    if (editable) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveMeasurements, child: const Text('Save Measurements'))),
                  ],
                ),
              ),

              // Events
              const SizedBox(height: 8),
              SectionHeader(title: 'Swim Events', trailing: eventsEditable ? null : TextButton(onPressed: () => setState(() => eventsEditable = true), child: const Text('Edit', style: TextStyle(color: AppColors.accent)))),
              AppCard(
                child: Column(
                  children: [
                    ...eventCtrl.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(child: TextField(controller: e['name'], enabled: eventsEditable, decoration: const InputDecoration(hintText: 'Event', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: e['time'], enabled: eventsEditable, decoration: const InputDecoration(hintText: 'Time', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
                      ]),
                    )),
                    if (eventCtrl.length < 5 && eventsEditable) TextButton.icon(onPressed: () => setState(() => eventCtrl.add({'name': TextEditingController(), 'time': TextEditingController()})), icon: const Icon(Icons.add, size: 18), label: const Text('Add Event')),
                    if (eventsEditable) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveEvents, child: const Text('Save Events'))),
                  ],
                ),
              ),

              // Logout
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async { await context.read<AuthProvider>().logout(); if (context.mounted) context.go('/guest-home'); },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  child: const Text('Logout'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { for (var c in mCtrl.values) c.dispose(); for (var e in eventCtrl) { e['name']?.dispose(); e['time']?.dispose(); } super.dispose(); }
}
