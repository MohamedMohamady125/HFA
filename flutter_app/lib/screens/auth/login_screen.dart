import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) { _showError(l.translate('fill_all_fields')); return; }

    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['token'];
      final userRes = await api.get('/users/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final user = userRes.data;

      if (user['role'] != 'athlete') { _showError(l.translate('athletes_only')); return; }

      final isApproved = user['approved'] == true || user['approved'] == 1;
      final authUser = {...Map<String, dynamic>.from(user), 'isLoggedIn': true, 'isApproved': isApproved, 'token': token};

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authUser', jsonEncode(authUser));
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go(isApproved ? '/athlete/home' : '/pending');
    } catch (e) {
      String msg = l.translate('login_failed');
      if (e is DioException && e.response?.data != null) msg = e.response!.data['detail']?.toString() ?? msg;
      _showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.pool_rounded, size: 36, color: AppColors.primary)),
            const SizedBox(height: 20),
            Text(l.translate('welcome_back'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(l.translate('sign_in_athlete'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 36),
            AppFormField(label: l.translate('email'), controller: _emailController, keyboardType: TextInputType.emailAddress, hint: l.translate('enter_email')),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(l.translate('password'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3))),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController, obscureText: _obscure, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(hintText: l.translate('enter_password'), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textTertiary, size: 20), onPressed: () => setState(() => _obscure = !_obscure))),
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text(l.translate('forgot_password'), style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('sign_in')),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.push('/register'),
              child: RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), children: [
                TextSpan(text: l.translate('no_account')),
                TextSpan(text: l.translate('register_now'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }
}
