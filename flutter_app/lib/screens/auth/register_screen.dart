import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedBranchId;
  bool _loading = false;

  final _branches = [
    {'label': 'Maadi', 'value': '1'}, {'label': 'Hadayek Al-Ahram', 'value': '2'},
    {'label': '6th October', 'value': '3'}, {'label': 'Nasr City', 'value': '4'}, {'label': 'New Cairo', 'value': '5'},
  ];

  Future<void> _handleRegister() async {
    final l = AppLocalizations.of(context);
    if ([_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl].any((c) => c.text.isEmpty) || _selectedBranchId == null) {
      _showMsg(l.translate('fill_all_fields'), isError: true); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) { _showMsg(l.translate('passwords_no_match'), isError: true); return; }
    if (!ConnectivityService.isOnline) {
      AppFeedback.showError(context, Exception(),
          fallback: l.translate('offline_register'));
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/register', data: {
        'email': _emailCtrl.text.trim(), 'password': _passCtrl.text, 'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(), 'branch_id': int.parse(_selectedBranchId!),
      });
      if (!mounted) return;
      for (var c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) {
        c.clear();
      }
      setState(() => _selectedBranchId = null);
      await _showSuccessDialog(l);
      if (mounted) AppFeedback.showSuccess(context, l.translate('registration_submitted'));
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('server_error'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _showSuccessDialog(AppLocalizations l) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
        title: Text(l.translate('successfully_registered')),
        content: Text(l.translate('registration_submitted'), textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.translate('ok'))),
        ],
      ),
    );
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppFeedback.showError(context, Exception(), fallback: msg);
    } else {
      AppFeedback.showSuccess(context, msg);
    }
  }

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
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xxl, 0, AppSpacing.xxl, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 20)],
              ),
              child: ClipOval(child: Image.asset('assets/images/hfanew.png', fit: BoxFit.cover)),
            )),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(delay: 60, child: Text(l.translate('create_account'), style: AppTypography.displayLarge)),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(delay: 120, child: Text(l.translate('join_academy'), style: AppTypography.bodyMedium)),
            const SizedBox(height: AppSpacing.xxxl),
            FadeSlideIn(delay: 180, child: AppFormField(
              label: l.translate('full_name'), controller: _nameCtrl, prefixIcon: Icons.person_outline_rounded)),
            FadeSlideIn(delay: 240, child: AppFormField(
              label: l.translate('email'), controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.mail_outline_rounded)),
            FadeSlideIn(delay: 300, child: AppFormField(
              label: l.translate('phone'), controller: _phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined)),
            FadeSlideIn(delay: 360, child: AppFormField(
              label: l.translate('password'), controller: _passCtrl, obscure: true, prefixIcon: Icons.lock_outline_rounded)),
            FadeSlideIn(delay: 420, child: AppFormField(
              label: l.translate('confirm_password'), controller: _confirmCtrl, obscure: true, prefixIcon: Icons.lock_outline_rounded)),
            FadeSlideIn(delay: 480, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.translate('branch'), style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                    value: _selectedBranchId,
                    hint: Text(l.translate('select_branch'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 15)),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
                    items: _branches.map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!))).toList(),
                    onChanged: (v) => setState(() => _selectedBranchId = v),
                  )),
                ),
              ],
            )),
            const SizedBox(height: AppSpacing.xxl),
            FadeSlideIn(delay: 540, child: PrimaryButton(
              label: l.translate('submit_registration'),
              loading: _loading,
              onPressed: _handleRegister,
            )),
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(delay: 600, child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(l.translate('registration_info'), style: AppTypography.bodyMedium.copyWith(fontSize: 13))),
              ]),
            )),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(delay: 660, child: Center(
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse('${ApiService.baseUrl}/privacy-policy'), mode: LaunchMode.externalApplication),
                child: Text(
                  l.translate('privacy_policy'),
                  style: AppTypography.label.copyWith(color: AppColors.accent, decoration: TextDecoration.underline),
                ),
              ),
            )),
          ],
        ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { for (var c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) { c.dispose(); } super.dispose(); }
}
