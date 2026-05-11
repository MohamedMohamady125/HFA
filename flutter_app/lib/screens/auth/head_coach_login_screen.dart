import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class HeadCoachLoginScreen extends StatefulWidget {
  const HeadCoachLoginScreen({super.key});
  @override
  State<HeadCoachLoginScreen> createState() => _HeadCoachLoginScreenState();
}

class _HeadCoachLoginScreenState extends State<HeadCoachLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['token'];
      final user = res.data['user'];

      if (user['role'] != 'head_coach') {
        _showError('Only head coach can login here.');
        return;
      }

      final authUser = {
        ...Map<String, dynamic>.from(user),
        'isLoggedIn': true,
        'isApproved': true,
        'token': token,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authUser', jsonEncode(authUser));
      await prefs.setString('headCoachMode', 'true');

      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go('/head-coach-branches');
    } catch (e) {
      String msg = 'Login failed';
      if (e is DioException && e.response?.data != null) {
        msg = e.response!.data['detail']?.toString() ?? msg;
      }
      _showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Text('\u{1F451} Head Coach Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF007AFF))),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  enabled: !_loading,
                  decoration: _inputDecoration('Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !_loading,
                  decoration: _inputDecoration('Password'),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _loading ? const Color(0xFF6CA0FF) : const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Login', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
