import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['token'];
      final userRes = await api.get('/users/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final user = userRes.data;

      if (user['role'] != 'athlete') {
        _showError('Only athletes can login here.');
        return;
      }

      final isApproved = user['approved'] == true || user['approved'] == 1;
      final authUser = {
        ...Map<String, dynamic>.from(user),
        'isLoggedIn': true,
        'isApproved': isApproved,
        'token': token,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authUser', jsonEncode(authUser));

      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);

      if (isApproved) {
        context.go('/athlete/home');
      } else {
        context.go('/pending');
      }
    } catch (e) {
      _showError(_extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      return data['detail']?.toString() ?? 'Server error';
    }
    return 'Login failed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: const Color(0xFF00D4FF).withValues(alpha: 0.1)),
            // Back button
            Positioned(
              top: 16, left: 24,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00D4FF)),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.9), elevation: 4),
              ),
            ),
            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
                        boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Center(child: Text('A', style: TextStyle(fontSize: 32, color: Color(0xFF00D4FF), fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(height: 20),
                    const Text('Athlete Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF00D4FF))),
                    const SizedBox(height: 8),
                    const Text('Welcome back, champion!', style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 32),

                    // Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15))],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            decoration: _inputDecoration('Enter your email'),
                          ),
                          const SizedBox(height: 20),
                          const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: _inputDecoration('Enter your password'),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _loading ? const Color(0xFF94A3B8) : const Color(0xFF00D4FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 6,
                              ),
                              child: Text(_loading ? 'Logging in...' : 'Login', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Forgot Password?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF00D4FF))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC).withValues(alpha: 0.8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF00D4FF).withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF00D4FF).withValues(alpha: 0.2))),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

