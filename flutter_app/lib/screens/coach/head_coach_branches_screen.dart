import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class HeadCoachBranchesScreen extends StatefulWidget {
  const HeadCoachBranchesScreen({super.key});
  @override
  State<HeadCoachBranchesScreen> createState() => _HeadCoachBranchesScreenState();
}

class _HeadCoachBranchesScreenState extends State<HeadCoachBranchesScreen> {
  List<dynamic> branches = [];
  bool loading = true;
  bool loggingIn = false;
  static const baseUrl = ApiService.baseUrl;

  static const coachCredentials = {
    2: {'email': 'hadayek@gmail.com', 'password': '1234'},
    3: {'email': 'maadi@gmail.com', 'password': '1234'},
    4: {'email': 'nasrcity@gmail.com', 'password': '1234'},
    5: {'email': 'newcairo@gmail.com', 'password': '1234'},
  };

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) {
        if (mounted) context.go('/guest-home');
        return;
      }
      final user = jsonDecode(stored);
      final res = await Dio().get('$baseUrl/branches', options: Options(headers: {'Authorization': 'Bearer ${user['token']}'}));
      branches = res.data;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load branches: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginAsCoach(Map<String, dynamic> branch) async {
    final creds = coachCredentials[branch['id']];
    if (creds == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No credentials for branch: ${branch['name']}'), backgroundColor: Colors.red));
      return;
    }

    setState(() => loggingIn = true);
    try {
      final res = await Dio().post('$baseUrl/auth/login', data: creds);
      final token = res.data['token'];
      final user = res.data['user'];

      if (!['coach', 'head_coach'].contains(user['role'])) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged in user is not a coach'), backgroundColor: Colors.red));
        return;
      }

      final authUser = {
        ...Map<String, dynamic>.from(user),
        'token': token,
        'isLoggedIn': true,
        'isApproved': true,
        'branch_id': branch['id'],
        'branch_name': branch['name'],
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authUser', jsonEncode(authUser));
      await prefs.remove('headCoachMode');

      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go('/coach/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || loggingIn) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: Color(0xFF007AFF)),
            const SizedBox(height: 12),
            Text(loggingIn ? 'Logging in...' : 'Loading branches...', style: const TextStyle(fontSize: 16, color: Color(0xFF007AFF))),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Select Branch to Manage', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF007AFF)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Expanded(
                child: branches.isEmpty
                    ? const Center(child: Text('No branches available.', style: TextStyle(fontSize: 18, color: Color(0xFF555555))))
                    : ListView.builder(
                        itemCount: branches.length,
                        itemBuilder: (_, i) {
                          final b = branches[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _loginAsCoach(Map<String, dynamic>.from(b)),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(b['address'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
                                    const SizedBox(height: 4),
                                    Text('\u{1F4DE} ${b['phone'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF007AFF))),
                                  ],
                                ),
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
