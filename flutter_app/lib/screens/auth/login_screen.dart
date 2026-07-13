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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context);
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) { _showError(l.translate('fill_all_fields')); return; }
    if (!ConnectivityService.isOnline) {
      AppFeedback.showError(context, Exception(),
          fallback: "You're offline — please connect to the internet to sign in.");
      return;
    }
    HapticFeedback.mediumImpact();
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
      if (!mounted) return;
      context.go(isApproved ? '/athlete/home' : '/pending');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('invalid_login'));
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 20)],
              ),
              child: ClipOval(child: Image.asset('assets/images/hfanew.png', fit: BoxFit.cover)),
            )),
            const SizedBox(height: AppSpacing.xxl),
            FadeSlideIn(delay: 60, child: Text(l.translate('welcome_back'), style: AppTypography.displayLarge)),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(delay: 120, child: Text(l.translate('sign_in_athlete'), style: AppTypography.bodyMedium)),
            const SizedBox(height: AppSpacing.xxxl),
            FadeSlideIn(delay: 180, child: AppFormField(
              label: l.translate('email'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              hint: l.translate('enter_email'),
              prefixIcon: Icons.mail_outline_rounded,
            )),
            FadeSlideIn(delay: 240, child: AppFormField(
              label: l.translate('password'),
              controller: _passCtrl,
              obscure: true,
              hint: l.translate('enter_password'),
              prefixIcon: Icons.lock_outline_rounded,
            )),
            FadeSlideIn(delay: 300, child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(l.translate('forgot_password'), style: AppTypography.label.copyWith(color: AppColors.accent)),
              ),
            )),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(delay: 360, child: PrimaryButton(
              label: l.translate('sign_in'),
              loading: _loading,
              onPressed: _handleLogin,
            )),
            const SizedBox(height: AppSpacing.xxl),
            FadeSlideIn(delay: 420, child: Center(
              child: TextButton(
                onPressed: () => context.push('/register'),
                child: RichText(text: TextSpan(style: AppTypography.bodyMedium, children: [
                  TextSpan(text: l.translate('no_account')),
                  TextSpan(text: l.translate('register_now'), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                ])),
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
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }
}
