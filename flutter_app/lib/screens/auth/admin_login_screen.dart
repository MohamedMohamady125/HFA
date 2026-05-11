import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

      if (user['role'] != 'coach' && user['role'] != 'head_coach') {
        _showError('Only coaches can access this page.');
        return;
      }

      final authUser = {
        ...Map<String, dynamic>.from(user),
        'isLoggedIn': true,
        'isApproved': user['approved'] == true || user['approved'] == 1,
        'token': token,
      };

      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);

      if (user['role'] == 'head_coach') {
        context.go('/head-coach-branches');
      } else {
        context.go('/coach/home');
      }
    } catch (e) {
      String msg = 'Server error';
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
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Image.asset('assets/images/hfanew.png', width: 120, height: 120),
                    const SizedBox(height: 12),
                    const Text('Coach Portal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    const Text('Access your coaching dashboard', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 32),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                        boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField('Email Address', _emailController, TextInputType.emailAddress),
                          _buildField('Password', _passwordController, null, obscure: true),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _loading ? const Color(0xFF94A3B8) : const Color(0xFF00D4FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Forgot Password?', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16, left: 20,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF475569)),
                style: IconButton.styleFrom(backgroundColor: Colors.white, elevation: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, TextInputType? keyboardType, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            enabled: !_loading,
            decoration: InputDecoration(
              hintText: 'Enter your ${label.toLowerCase()}',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
