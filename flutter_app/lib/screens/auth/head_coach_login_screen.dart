import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../l10n/app_localizations.dart';

class HeadCoachLoginScreen extends StatefulWidget {
  const HeadCoachLoginScreen({super.key});
  @override
  State<HeadCoachLoginScreen> createState() => _HeadCoachLoginScreenState();
}

class _HeadCoachLoginScreenState extends State<HeadCoachLoginScreen> {
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
      final res = await ApiService().post('/auth/login', data: {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text.trim()});
      final token = res.data['token']; final user = res.data['user'];
      if (user['role'] != 'head_coach') { _showError(l.translate('head_coach_only')); return; }
      final authUser = {...Map<String, dynamic>.from(user), 'isLoggedIn': true, 'isApproved': true, 'token': token};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authUser', jsonEncode(authUser));
      await prefs.setString('headCoachMode', 'true');
      if (!mounted) return;
      await context.read<AuthProvider>().login(authUser);
      if (!mounted) return;
      context.go('/head-coach-branches');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('login_failed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            const FadeSlideIn(child: IconBadge(icon: Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 64, radius: 20)),
            const SizedBox(height: AppSpacing.xxl),
            FadeSlideIn(delay: 60, child: Text(l.translate('head_coach'), style: AppTypography.displayLarge)),
            const SizedBox(height: AppSpacing.xxxl),
            FadeSlideIn(delay: 120, child: AppFormField(
              label: l.translate('email'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              enabled: !_loading,
              prefixIcon: Icons.mail_outline_rounded,
            )),
            FadeSlideIn(delay: 180, child: AppFormField(
              label: l.translate('password'),
              controller: _passCtrl,
              obscure: true,
              enabled: !_loading,
              prefixIcon: Icons.lock_outline_rounded,
            )),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(delay: 240, child: PrimaryButton(
              label: l.translate('sign_in'),
              loading: _loading,
              onPressed: _handleLogin,
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
