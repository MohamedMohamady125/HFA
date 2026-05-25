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
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false, _obscure = true;

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context);
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) { _showError(l.translate('fill_all_fields')); return; }
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.post('/auth/login', data: {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text.trim()});
      final token = res.data['token'];
      final userRes = await api.get('/users/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final user = userRes.data;
      if (user['role'] != 'athlete') { _showError(l.translate('athletes_only')); return; }
      final isApproved = user['approved'] == true || user['approved'] == 1;
      final authUser = {...Map<String, dynamic>.from(user), 'isLoggedIn': true, 'isApproved': isApproved, 'token': token};
      await (await SharedPreferences.getInstance()).setString('authUser', jsonEncode(authUser));
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go(isApproved ? '/athlete/home' : '/pending');
    } catch (e) {
      _showError(e is DioException ? (e.response?.data?['detail']?.toString() ?? 'Login failed') : 'Login failed');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showError(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error)); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 16),
            FadeSlideIn(child: Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(child: Image.asset('assets/images/hfanew.png', fit: BoxFit.cover)),
            )),
            const SizedBox(height: 20),
            FadeSlideIn(delay: 100, child: Text(l.translate('welcome_back'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
            const SizedBox(height: 6),
            FadeSlideIn(delay: 150, child: Text(l.translate('sign_in_athlete'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
            const SizedBox(height: 44),
            FadeSlideIn(delay: 200, child: AppFormField(label: l.translate('email'), controller: _emailCtrl, keyboardType: TextInputType.emailAddress, hint: l.translate('enter_email'))),
            FadeSlideIn(delay: 250, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.translate('password'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              TextField(controller: _passCtrl, obscureText: _obscure, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(hintText: l.translate('enter_password'),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textTertiary, size: 20), onPressed: () => setState(() => _obscure = !_obscure)))),
            ])),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'),
              child: Text(l.translate('forgot_password'), style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)))),
            const SizedBox(height: 12),
            FadeSlideIn(delay: 350, child: SizedBox(width: double.infinity, child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(backgroundColor: _loading ? AppColors.textTertiary : AppColors.accent),
                child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                  child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('sign_in'), key: const ValueKey('signin'))),
              ),
            ))),
            const SizedBox(height: 28),
            FadeSlideIn(delay: 400, child: TextButton(onPressed: () => context.push('/register'),
              child: RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), children: [
                TextSpan(text: l.translate('no_account')),
                TextSpan(text: l.translate('register_now'), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
              ])))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }
}
