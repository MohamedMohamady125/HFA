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

class ParentCodeScreen extends StatefulWidget {
  const ParentCodeScreen({super.key});
  @override
  State<ParentCodeScreen> createState() => _ParentCodeScreenState();
}

class _ParentCodeScreenState extends State<ParentCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context);
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) { _showError(l.translate('enter_code')); return; }
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.post('/auth/login-with-code', data: {'code': code});
      final token = res.data['token'];
      final userRes = await api.get('/users/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final user = userRes.data;
      final isApproved = user['approved'] == true || user['approved'] == 1;
      final authUser = {...Map<String, dynamic>.from(user), 'isLoggedIn': true, 'isApproved': isApproved, 'token': token};
      await (await SharedPreferences.getInstance()).setString('authUser', jsonEncode(authUser));
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      context.go(isApproved ? '/athlete/home' : '/pending');
    } catch (e) {
      _showError(e is DioException ? (e.response?.data?['detail']?.toString() ?? l.translate('invalid_code')) : l.translate('invalid_code'));
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
            const SizedBox(height: 24),
            FadeSlideIn(child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.family_restroom_rounded, color: AppColors.accent, size: 36),
            )),
            const SizedBox(height: 24),
            FadeSlideIn(delay: 100, child: Text(l.translate('parent_access'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
            const SizedBox(height: 8),
            FadeSlideIn(delay: 150, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l.translate('parent_login_desc'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
            )),
            const SizedBox(height: 40),
            FadeSlideIn(delay: 200, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.translate('access_code'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                    counterText: '',
                  ),
                ),
              ],
            )),
            const SizedBox(height: 32),
            FadeSlideIn(delay: 300, child: SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(backgroundColor: _loading ? AppColors.textTertiary : AppColors.accent),
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('sign_in'), key: const ValueKey('signin'))),
            ))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }
}
