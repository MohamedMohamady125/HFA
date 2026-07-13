import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 0 = enter email, 1 = enter code, 2 = new password
  int _step = 0;
  bool _loading = false;

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  void _showError(String msg) {
    if (mounted) AppFeedback.showError(context, Exception(), fallback: msg);
  }

  bool _checkOnline() {
    if (ConnectivityService.isOnline) return true;
    AppFeedback.showError(context, Exception(),
        fallback: "You're offline — please connect to the internet to reset your password.");
    return false;
  }

  // Step 1: Send code to email
  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    if (_emailCtrl.text.trim().isEmpty) { _showError(l.translate('fill_all_fields')); return; }
    if (!_checkOnline()) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/forgot-password', data: {'email': _emailCtrl.text.trim()});
      if (mounted) setState(() => _step = 1);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('login_failed'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  // Step 2: Verify code
  Future<void> _verifyCode() async {
    final l = AppLocalizations.of(context);
    if (_codeCtrl.text.trim().isEmpty) { _showError(l.translate('enter_code')); return; }
    if (!_checkOnline()) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/verify-reset-code', data: {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
      });
      if (mounted) setState(() => _step = 2);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('invalid_code'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  // Step 3: Reset password
  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context);
    if (_passCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) { _showError(l.translate('fill_all_fields')); return; }
    if (_passCtrl.text != _confirmCtrl.text) { _showError(l.translate('passwords_no_match')); return; }
    if (!_checkOnline()) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/reset-password', data: {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'new_password': _passCtrl.text,
      });
      if (mounted) {
        AppFeedback.showSuccess(context, l.translate('password_reset_success'));
        context.pop();
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('password_failed'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () {
          if (_step > 0) { setState(() => _step--); } else { context.pop(); }
        }),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(child: IconBadge(
              icon: _step == 0 ? Icons.email_outlined : _step == 1 ? Icons.pin_outlined : Icons.lock_outline_rounded,
              color: AppColors.accent,
              size: 64,
              radius: 20,
            )),
            const SizedBox(height: AppSpacing.xl),

            // Step indicator
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _step == i ? 24 : 8, height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _step >= i ? AppColors.accent : AppColors.textTertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
            const SizedBox(height: AppSpacing.xxl),

            if (_step == 0) ..._buildEmailStep(l),
            if (_step == 1) ..._buildCodeStep(l),
            if (_step == 2) ..._buildPasswordStep(l),

            const SizedBox(height: 40),
          ],
        ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEmailStep(AppLocalizations l) => [
    FadeSlideIn(delay: 60, child: Text(l.translate('reset_password'), style: AppTypography.displayLarge, textAlign: TextAlign.center)),
    const SizedBox(height: AppSpacing.sm),
    FadeSlideIn(delay: 120, child: Text(l.translate('forgot_desc'), style: AppTypography.bodyMedium, textAlign: TextAlign.center)),
    const SizedBox(height: AppSpacing.xxxl),
    FadeSlideIn(delay: 180, child: AppFormField(
      label: l.translate('email'),
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      hint: l.translate('enter_email'),
      prefixIcon: Icons.mail_outline_rounded,
    )),
    const SizedBox(height: AppSpacing.sm),
    FadeSlideIn(delay: 240, child: PrimaryButton(
      label: l.translate('send_code'),
      loading: _loading,
      onPressed: _sendCode,
    )),
  ];

  List<Widget> _buildCodeStep(AppLocalizations l) => [
    FadeSlideIn(delay: 60, child: Text(l.translate('enter_reset_code'), style: AppTypography.displayLarge, textAlign: TextAlign.center)),
    const SizedBox(height: AppSpacing.sm),
    FadeSlideIn(delay: 120, child: Text(l.translate('code_sent_to_email'), style: AppTypography.bodyMedium, textAlign: TextAlign.center)),
    const SizedBox(height: AppSpacing.sm),
    FadeSlideIn(delay: 180, child: Text(_emailCtrl.text.trim(), style: AppTypography.titleMedium.copyWith(color: AppColors.accent))),
    const SizedBox(height: AppSpacing.xxxl),
    FadeSlideIn(delay: 240, child: TextField(
      controller: _codeCtrl,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.textPrimary),
      maxLength: 6,
      decoration: InputDecoration(
        hintText: '------',
        hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.textTertiary.withValues(alpha: 0.3)),
        counterText: '',
      ),
    )),
    const SizedBox(height: AppSpacing.sm),
    FadeSlideIn(delay: 300, child: Text(l.translate('code_expires_15'), style: AppTypography.caption)),
    const SizedBox(height: AppSpacing.xxl),
    FadeSlideIn(delay: 360, child: PrimaryButton(
      label: l.translate('verify_code'),
      loading: _loading,
      onPressed: _verifyCode,
    )),
    const SizedBox(height: AppSpacing.md),
    FadeSlideIn(delay: 420, child: TextButton(
      onPressed: _loading ? null : _sendCode,
      child: Text(l.translate('resend_code'), style: AppTypography.label.copyWith(color: AppColors.accent)),
    )),
  ];

  List<Widget> _buildPasswordStep(AppLocalizations l) => [
    FadeSlideIn(delay: 60, child: Text(l.translate('new_password_title'), style: AppTypography.displayLarge, textAlign: TextAlign.center)),
    const SizedBox(height: AppSpacing.sm),
    FadeSlideIn(delay: 120, child: Text(l.translate('new_password_desc'), style: AppTypography.bodyMedium, textAlign: TextAlign.center)),
    const SizedBox(height: AppSpacing.xxxl),
    FadeSlideIn(delay: 180, child: AppFormField(
      label: l.translate('new_password'),
      controller: _passCtrl,
      obscure: true,
      hint: l.translate('enter_password'),
      prefixIcon: Icons.lock_outline_rounded,
    )),
    FadeSlideIn(delay: 240, child: AppFormField(
      label: l.translate('confirm_password'),
      controller: _confirmCtrl,
      obscure: true,
      hint: l.translate('confirm_new_password'),
      prefixIcon: Icons.lock_outline_rounded,
    )),
    const SizedBox(height: AppSpacing.md),
    FadeSlideIn(delay: 300, child: PrimaryButton(
      label: l.translate('update_password'),
      loading: _loading,
      onPressed: _resetPassword,
    )),
  ];

  @override
  void dispose() { _emailCtrl.dispose(); _codeCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }
}
