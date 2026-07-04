import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
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
  bool _obscure = true;

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  void _showSuccess(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  }

  // Step 1: Send code to email
  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    if (_emailCtrl.text.trim().isEmpty) { _showError(l.translate('fill_all_fields')); return; }
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/forgot-password', data: {'email': _emailCtrl.text.trim()});
      if (mounted) setState(() => _step = 1);
    } catch (e) {
      _showError(e is DioException ? (e.response?.data?['detail']?.toString() ?? l.translate('login_failed')) : l.translate('login_failed'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  // Step 2: Verify code
  Future<void> _verifyCode() async {
    final l = AppLocalizations.of(context);
    if (_codeCtrl.text.trim().isEmpty) { _showError(l.translate('enter_code')); return; }
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/verify-reset-code', data: {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
      });
      if (mounted) setState(() => _step = 2);
    } catch (e) {
      _showError(e is DioException ? (e.response?.data?['detail']?.toString() ?? l.translate('invalid_code')) : l.translate('invalid_code'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  // Step 3: Reset password
  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context);
    if (_passCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) { _showError(l.translate('fill_all_fields')); return; }
    if (_passCtrl.text != _confirmCtrl.text) { _showError(l.translate('passwords_no_match')); return; }
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/reset-password', data: {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'new_password': _passCtrl.text,
      });
      if (mounted) {
        _showSuccess(l.translate('password_reset_success'));
        context.pop();
      }
    } catch (e) {
      _showError(e is DioException ? (e.response?.data?['detail']?.toString() ?? l.translate('password_failed')) : l.translate('password_failed'));
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 16),
            FadeSlideIn(child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _step == 0 ? Icons.email_outlined : _step == 1 ? Icons.pin_outlined : Icons.lock_outline_rounded,
                color: AppColors.accent, size: 30,
              ),
            )),
            const SizedBox(height: 20),

            // Step indicator
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
              Container(
                width: _step == i ? 24 : 8, height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _step >= i ? AppColors.accent : AppColors.textTertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
            const SizedBox(height: 24),

            if (_step == 0) ..._buildEmailStep(l),
            if (_step == 1) ..._buildCodeStep(l),
            if (_step == 2) ..._buildPasswordStep(l),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep(AppLocalizations l) => [
    FadeSlideIn(delay: 100, child: Text(l.translate('reset_password'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
    const SizedBox(height: 8),
    FadeSlideIn(delay: 150, child: Text(l.translate('forgot_desc'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center)),
    const SizedBox(height: 36),
    FadeSlideIn(delay: 200, child: AppFormField(label: l.translate('email'), controller: _emailCtrl, keyboardType: TextInputType.emailAddress, hint: l.translate('enter_email'))),
    const SizedBox(height: 24),
    FadeSlideIn(delay: 300, child: SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: _loading ? null : _sendCode,
      child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('send_code')),
    ))),
  ];

  List<Widget> _buildCodeStep(AppLocalizations l) => [
    FadeSlideIn(delay: 100, child: Text(l.translate('enter_reset_code'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
    const SizedBox(height: 8),
    FadeSlideIn(delay: 150, child: Text(l.translate('code_sent_to_email'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center)),
    const SizedBox(height: 8),
    FadeSlideIn(delay: 200, child: Text(_emailCtrl.text.trim(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent))),
    const SizedBox(height: 36),
    FadeSlideIn(delay: 250, child: TextField(
      controller: _codeCtrl,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8),
      maxLength: 6,
      decoration: InputDecoration(
        hintText: '------',
        hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.textTertiary.withValues(alpha: 0.3)),
        counterText: '',
      ),
    )),
    const SizedBox(height: 8),
    FadeSlideIn(delay: 300, child: Text(l.translate('code_expires_15'), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary))),
    const SizedBox(height: 24),
    FadeSlideIn(delay: 350, child: SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: _loading ? null : _verifyCode,
      child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('verify_code')),
    ))),
    const SizedBox(height: 12),
    FadeSlideIn(delay: 400, child: TextButton(
      onPressed: _loading ? null : _sendCode,
      child: Text(l.translate('resend_code'), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
    )),
  ];

  List<Widget> _buildPasswordStep(AppLocalizations l) => [
    FadeSlideIn(delay: 100, child: Text(l.translate('new_password_title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
    const SizedBox(height: 8),
    FadeSlideIn(delay: 150, child: Text(l.translate('new_password_desc'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center)),
    const SizedBox(height: 36),
    FadeSlideIn(delay: 200, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.translate('new_password'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      TextField(controller: _passCtrl, obscureText: _obscure, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: l.translate('enter_password'),
          suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textTertiary, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
        )),
    ])),
    const SizedBox(height: 16),
    FadeSlideIn(delay: 250, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.translate('confirm_password'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      TextField(controller: _confirmCtrl, obscureText: true, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(hintText: l.translate('confirm_new_password'))),
    ])),
    const SizedBox(height: 28),
    FadeSlideIn(delay: 350, child: SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: _loading ? null : _resetPassword,
      child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('update_password')),
    ))),
  ];

  @override
  void dispose() { _emailCtrl.dispose(); _codeCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }
}
