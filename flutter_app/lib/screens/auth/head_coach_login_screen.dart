import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HeadCoachLoginScreen extends StatefulWidget {
  const HeadCoachLoginScreen({super.key});
  @override
  State<HeadCoachLoginScreen> createState() => _HeadCoachLoginScreenState();
}

class _HeadCoachLoginScreenState extends State<HeadCoachLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) { _showError('Please enter email and password'); return; }
    setState(() => _loading = true);
    try {
      final res = await ApiService().post('/auth/login', data: {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text.trim()});
      final token = res.data['token']; final user = res.data['user'];
      if (user['role'] != 'head_coach') { _showError('Only head coach can login here.'); return; }
      final authUser = {...Map<String, dynamic>.from(user), 'isLoggedIn': true, 'isApproved': true, 'token': token};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authUser', jsonEncode(authUser));
      await prefs.setString('headCoachMode', 'true');
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go('/head-coach-branches');
    } catch (e) {
      String msg = 'Login failed';
      if (e is DioException && e.response?.data != null) msg = e.response!.data['detail']?.toString() ?? msg;
      _showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Head Coach', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 36),
              AppCard(
                child: Column(
                  children: [
                    AppFormField(label: 'EMAIL', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, enabled: !_loading),
                    AppFormField(label: 'PASSWORD', controller: _passCtrl, obscure: true, enabled: !_loading),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }
}
