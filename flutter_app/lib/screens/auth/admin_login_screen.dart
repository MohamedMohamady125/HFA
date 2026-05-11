import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
      if (user['role'] != 'coach' && user['role'] != 'head_coach') { _showError(l.translate('coaches_only')); return; }
      final authUser = {...Map<String, dynamic>.from(user), 'isLoggedIn': true, 'isApproved': user['approved'] == true || user['approved'] == 1, 'token': token};
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go(user['role'] == 'head_coach' ? '/head-coach-branches' : '/coach/home');
    } catch (e) {
      String msg = l.translate('login_failed');
      if (e is DioException && e.response?.data != null) msg = e.response!.data['detail']?.toString() ?? msg;
      _showError(msg);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(children: [
          const SizedBox(height: 20),
          Image.asset('assets/images/hfanew.png', width: 80, height: 80),
          const SizedBox(height: 20),
          Text(l.translate('coach_portal'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(l.translate('access_dashboard'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 36),
          AppCard(child: Column(children: [
            AppFormField(label: l.translate('email'), controller: _emailCtrl, keyboardType: TextInputType.emailAddress, enabled: !_loading),
            Align(alignment: Alignment.centerLeft, child: Text(l.translate('password'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3))),
            const SizedBox(height: 8),
            TextField(controller: _passCtrl, obscureText: _obscure, enabled: !_loading, decoration: InputDecoration(hintText: l.translate('enter_password'), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textTertiary, size: 20), onPressed: () => setState(() => _obscure = !_obscure)))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _handleLogin, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('sign_in')))),
            const SizedBox(height: 12),
            TextButton(onPressed: () => context.push('/forgot-password'), child: Text(l.translate('forgot_password'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          ])),
        ]),
      ),
    );
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }
}
