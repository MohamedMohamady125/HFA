import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
  Map<String, String> paymentHistory = {};

  // Measurements
  Map<String, TextEditingController> mCtrl = {};
  bool mEditable = true;
  final _mKeys = ['height', 'weight', 'arm', 'leg', 'fat', 'muscle'];

  // Events
  List<Map<String, TextEditingController>> eventCtrl = [];
  bool eventsEditable = true;

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
    user = jsonDecode(stored);
    final api = ApiService();

    try {
      final results = await Future.wait([
        api.get('/attendance/athlete/${user!['id']}/week'),
        api.get('/branches/${user!['branch_id']}'),
        api.get('/attendance/branch/${user!['branch_id']}/session-dates'),
      ]);
      attendance = results[0].data;
      branchName = results[1].data['name'] ?? '';
      if (results[2].data is List) {
        labels = List.generate((results[2].data as List).length, (i) => 'Day ${i + 1}');
      }
    } catch (_) {}

    // Measurements
    try {
      final mRes = await api.get('/athlete/measurements');
      final mData = mRes.data is List ? (mRes.data as List).firstOrNull : mRes.data;
      if (mData != null) {
        for (var k in _mKeys) mCtrl[k]!.text = mData[k]?.toString() ?? '';
        mEditable = false;
      }
    } catch (_) {}

    // Events
    try {
      final evts = await api.get('/athlete/performance-logs');
      if (evts.data is List && (evts.data as List).isNotEmpty) {
        eventCtrl = (evts.data as List).map((e) => {
          'name': TextEditingController(text: e['event_name'] ?? ''),
          'time': TextEditingController(text: e['result_time']?.toString() ?? ''),
        }).toList();
        eventsEditable = false;
      }
    } catch (_) {}

    // Payment history
    try {
      final payRes = await api.get('/payments/${user!['id']}/status');
      if (payRes.data is Map) {
        paymentHistory = Map<String, String>.from(payRes.data);
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _saveMeasurements() async {
    try {
      final data = <String, double>{};
      for (var k in _mKeys) data[k] = double.tryParse(mCtrl[k]!.text) ?? 0;
      await ApiService().post('/athlete/measurements', data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurements saved!'), backgroundColor: AppColors.success));
        setState(() => mEditable = false);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _saveEvents() async {
    try {
      final api = ApiService();
      final valid = eventCtrl.where((e) => e['name']!.text.isNotEmpty && e['time']!.text.isNotEmpty).toList();
      if (valid.isEmpty) return;
      try { await api.delete('/athlete/performance-logs'); } catch (_) {}
      for (var e in valid) {
        await api.post('/athlete/performance-log', data: {
          'meet_name': 'Top Swim Event',
          'meet_date': DateTime.now().toIso8601String().split('T')[0],
          'event_name': e['name']!.text,
          'result_time': double.tryParse(e['time']!.text) ?? 0,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Events saved!'), backgroundColor: AppColors.success));
        setState(() => eventsEditable = false);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _showChangeEmail() async {
    final emailCtrl = TextEditingController(text: user!['email'] ?? '');
    final passCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Email', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New Email')),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );

    if (result != true || emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) return;

    try {
      await ApiService().post('/auth/change-email', data: {'new_email': emailCtrl.text.trim(), 'password': passCtrl.text});
      // Update local stored user
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored != null) {
        final authUser = Map<String, dynamic>.from(jsonDecode(stored));
        authUser['email'] = emailCtrl.text.trim();
        await prefs.setString('authUser', jsonEncode(authUser));
        user = authUser;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated successfully'), backgroundColor: AppColors.success));
        setState(() {});
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update email'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _showChangePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );

    if (result != true) return;
    if (newCtrl.text != confirmCtrl.text) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error));
      return;
    }
    if (newCtrl.text.isEmpty || oldCtrl.text.isEmpty) return;

    try {
      await ApiService().post('/auth/change-password', data: {'old_password': oldCtrl.text, 'new_password': newCtrl.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully'), backgroundColor: AppColors.success));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (user == null) return const AppLoadingScreen();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Header ──
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (user!['name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user!['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(branchName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _infoRow(Icons.email_rounded, l.translate('email'), user!['email'] ?? ''),
                      if (user!['phone'] != null && user!['phone'].toString().isNotEmpty)
                        _infoRow(Icons.phone_rounded, l.translate('phone'), user!['phone']),
                    ],
                  ),
                ),

                // ── Attendance ──
                const SizedBox(height: 16),
                SectionHeader(title: l.translate('attendance_tracker')),
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
                        Icon(
                          status == 'present' ? Icons.check_circle_rounded : status == 'absent' ? Icons.cancel_rounded : Icons.remove_circle_outline,
                          color: color, size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status == 'present' ? l.translate('present') : status == 'absent' ? l.translate('absent') : '-',
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),

                // ── Payment History ──
                const SizedBox(height: 16),
                SectionHeader(title: l.translate('payment')),
                AppCard(
                  child: paymentHistory.isEmpty
                      ? const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No payment records yet', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                        ))
                      : Column(
                          children: paymentHistory.entries.toList().reversed.take(6).map((entry) {
                            final statusText = entry.value;
                            final color = statusText == 'paid' ? AppColors.success : statusText == 'late' ? AppColors.error : AppColors.warning;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                                  StatusBadge(label: statusText.toUpperCase(), color: color),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),

                // ── Measurements ──
                const SizedBox(height: 16),
                SectionHeader(
                  title: l.translate('measurements'),
                  trailing: mEditable ? null : TextButton(
                    onPressed: () => setState(() => mEditable = true),
                    child: Text(l.translate('edit'), style: const TextStyle(color: AppColors.accent)),
                  ),
                ),
                AppCard(
                  child: Column(
                    children: [
                      ..._mKeys.map((k) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          SizedBox(width: 100, child: Text(l.translate(k), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
                          Expanded(child: TextField(
                            controller: mCtrl[k],
                            keyboardType: TextInputType.number,
                            enabled: mEditable,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
                          )),
                        ]),
                      )),
                      if (mEditable) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveMeasurements, child: Text(l.translate('save_measurements')))),
                    ],
                  ),
                ),

                // ── Swim Events ──
                const SizedBox(height: 16),
                SectionHeader(
                  title: l.translate('swim_events'),
                  trailing: eventsEditable ? null : TextButton(
                    onPressed: () => setState(() => eventsEditable = true),
                    child: Text(l.translate('edit'), style: const TextStyle(color: AppColors.accent)),
                  ),
                ),
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
                      if (eventCtrl.length < 5 && eventsEditable) TextButton.icon(
                        onPressed: () => setState(() => eventCtrl.add({'name': TextEditingController(), 'time': TextEditingController()})),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.translate('add_event')),
                      ),
                      if (eventsEditable) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveEvents, child: Text(l.translate('save_events')))),
                    ],
                  ),
                ),

                // ── Settings ──
                const SizedBox(height: 24),
                SectionHeader(title: l.translate('settings')),
                AppCard(
                  onTap: _showChangeEmail,
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.email_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(l.translate('change_email'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                    ],
                  ),
                ),
                AppCard(
                  onTap: _showChangePassword,
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(l.translate('change_password'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/guest-home');
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(l.translate('logout')),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var c in mCtrl.values) c.dispose();
    for (var e in eventCtrl) { e['name']?.dispose(); e['time']?.dispose(); }
    super.dispose();
  }
}
