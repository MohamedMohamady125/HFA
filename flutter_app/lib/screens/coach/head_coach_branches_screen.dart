import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HeadCoachBranchesScreen extends StatefulWidget {
  const HeadCoachBranchesScreen({super.key});
  @override
  State<HeadCoachBranchesScreen> createState() => _HeadCoachBranchesScreenState();
}

class _HeadCoachBranchesScreenState extends State<HeadCoachBranchesScreen> {
  List<dynamic> branches = [];
  bool loading = true, loggingIn = false;

  static const coachCredentials = {
    2: {'email': 'hadayek@gmail.com', 'password': '1234'},
    3: {'email': 'maadi@gmail.com', 'password': '1234'},
    4: {'email': 'nasrcity@gmail.com', 'password': '1234'},
    5: {'email': 'newcairo@gmail.com', 'password': '1234'},
  };

  @override
  void initState() { super.initState(); _fetchBranches(); }

  Future<void> _fetchBranches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) { if (mounted) context.go('/guest-home'); return; }
      final user = jsonDecode(stored);
      final res = await Dio().get('${ApiService.baseUrl}/branches', options: Options(headers: {'Authorization': 'Bearer ${user['token']}'}));
      branches = res.data;
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loginAsCoach(Map<String, dynamic> branch) async {
    final creds = coachCredentials[branch['id']];
    if (creds == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No credentials for ${branch['name']}'), backgroundColor: AppColors.error)); return; }
    setState(() => loggingIn = true);
    try {
      final res = await Dio().post('${ApiService.baseUrl}/auth/login', data: creds);
      final authUser = {...Map<String, dynamic>.from(res.data['user']), 'token': res.data['token'], 'isLoggedIn': true, 'isApproved': true, 'branch_id': branch['id'], 'branch_name': branch['name']};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authUser', jsonEncode(authUser));
      await prefs.remove('headCoachMode');
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go('/coach/home');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed'), backgroundColor: AppColors.error));
    } finally { if (mounted) setState(() => loggingIn = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || loggingIn) return AppLoadingScreen(message: loggingIn ? 'Switching branch...' : 'Loading branches...');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Branch', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text('Choose a branch to manage', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Expanded(
                child: branches.isEmpty
                    ? const Center(child: Text('No branches available.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        itemCount: branches.length,
                        itemBuilder: (_, i) {
                          final b = branches[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              onTap: () => _loginAsCoach(Map<String, dynamic>.from(b)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.location_city_rounded, color: AppColors.accent),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(b['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    if (b['address'] != null) Text(b['address'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ])),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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
}
