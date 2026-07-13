import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
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
    if (!ConnectivityService.isOnline) {
      AppFeedback.showError(context, Exception(),
          fallback: "You're offline — please connect to the internet to sign in.");
      return;
    }
    HapticFeedback.mediumImpact();
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
      if (!mounted) return;
      context.go(isApproved ? '/athlete/home' : '/pending');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('invalid_code'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showError(String msg) { if (mounted) AppFeedback.showError(context, Exception(), fallback: msg); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const FadeSlideIn(child: IconBadge(icon: Icons.family_restroom_rounded, color: AppColors.accent, size: 72, radius: 22)),
            const SizedBox(height: AppSpacing.xxl),
            FadeSlideIn(delay: 60, child: Text(l.translate('parent_access'), style: AppTypography.displayLarge, textAlign: TextAlign.center)),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(delay: 120, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(l.translate('parent_login_desc'), style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            )),
            const SizedBox(height: AppSpacing.xxxl),
            FadeSlideIn(delay: 180, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.translate('access_code'), style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.textPrimary),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                    counterText: '',
                  ),
                ),
              ],
            )),
            const SizedBox(height: AppSpacing.xxxl),
            FadeSlideIn(delay: 240, child: SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l.translate('sign_in'),
                loading: _loading,
                onPressed: _handleLogin,
              ),
            )),
            const SizedBox(height: 40),
          ],
        ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }
}
