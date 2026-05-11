import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CoachProfileScreen extends StatefulWidget {
  const CoachProfileScreen({super.key});
  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  String branchName = '';

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    try {
      final res = await Dio().get('${ApiService.baseUrl}/users/me', options: Options(headers: {'Authorization': 'Bearer ${auth.token}'}));
      if (mounted) setState(() => branchName = res.data['branch_name'] ?? '');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              const Text('\u{1F464} Coach Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]),
                child: Column(
                  children: [
                    Text(auth.userName ?? 'Coach Name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('\u{1F4CD} ${branchName.isNotEmpty ? branchName : 'Branch Name'}', style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
                    Text(auth.userEmail ?? 'coach@email.com', style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Quick Actions
              _sectionTitle('\u{26A1} Quick Actions'),
              _actionButton('Edit Profile', () => context.push('/edit-profile')),
              _actionButton('Change Password', () => context.push('/change-password')),
              const SizedBox(height: 25),

              // Attendance
              _sectionTitle('\u{1F4CA} Attendance'),
              _actionButton('Branch Attendance Summary', () => context.push('/coach-manage/attendance')),
              const SizedBox(height: 25),

              // Logout
              OutlinedButton(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/guest-home');
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))));

  Widget _actionButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
