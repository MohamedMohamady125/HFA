import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../l10n/app_localizations.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context);
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) { _showError(l.translate('fill_all_fields')); return; }
    if (!ConnectivityService.isOnline) {
      AppFeedback.showError(context, Exception(),
          fallback: l.translate('offline_sign_in'));
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
      if (user['role'] != 'coach' && user['role'] != 'head_coach') { _showError(l.translate('coaches_only')); return; }
      final authUser = {...Map<String, dynamic>.from(user), 'isLoggedIn': true, 'isApproved': user['approved'] == true || user['approved'] == 1, 'token': token};
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      if (!mounted) return;
      context.go(user['role'] == 'head_coach' ? '/head-coach-branches' : '/coach/home');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('login_failed'));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
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
            const FadeSlideIn(child: IconBadge(icon: Icons.sports_rounded, color: AppColors.primary, size: 64, radius: 20)),
            const SizedBox(height: AppSpacing.xxl),
            FadeSlideIn(delay: 60, child: Text(l.translate('coach_portal'), style: AppTypography.displayLarge)),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(delay: 120, child: Text(l.translate('access_dashboard'), style: AppTypography.bodyMedium)),
            const SizedBox(height: AppSpacing.xxxl),
            FadeSlideIn(delay: 180, child: AppFormField(
              label: l.translate('email'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              enabled: !_loading,
              prefixIcon: Icons.mail_outline_rounded,
            )),
            FadeSlideIn(delay: 240, child: AppFormField(
              label: l.translate('password'),
              controller: _passCtrl,
              obscure: true,
              enabled: !_loading,
              hint: l.translate('enter_password'),
              prefixIcon: Icons.lock_outline_rounded,
            )),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(delay: 300, child: PrimaryButton(
              label: l.translate('sign_in'),
              loading: _loading,
              onPressed: _handleLogin,
            )),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(delay: 360, child: Center(
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(l.translate('forgot_password'), style: AppTypography.label),
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
