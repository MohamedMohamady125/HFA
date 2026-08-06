import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/connectivity_service.dart';
import '../../services/offline/offline_repository.dart';
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

  List<Map<String, String>> _branches = [];

  @override
  void initState() {
    super.initState();
    // Cache-first: show cached branches instantly (works offline once visited).
    final cached = OfflineRepository.getCached('branches_public_list');
    if (cached is List) _applyBranches(cached);
    _fetchBranches();
  }

  void _applyBranches(List data) {
    _branches = data
        .map((b) => {'label': (b['name'] ?? '').toString(), 'value': (b['id'] ?? '').toString()})
        .where((b) => b['label']!.isNotEmpty && b['value']!.isNotEmpty)
        .toList();
    // Drop selection if the branch no longer exists.
    if (_selectedBranchId != null && !_branches.any((b) => b['value'] == _selectedBranchId)) {
      _selectedBranchId = null;
    }
  }

  Future<void> _fetchBranches() async {
    final data = await OfflineRepository.getPublicBranches(onFresh: (fresh) {
      if (mounted && fresh is List) setState(() => _applyBranches(fresh));
    });
    if (mounted && data.isNotEmpty) setState(() => _applyBranches(data));
  }

  Future<void> _handleRegister() async {
    final l = AppLocalizations.of(context);
    if ([_nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl].any((c) => c.text.isEmpty) || _selectedBranchId == null) {
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
      final res = await ApiService().post('/auth/register', data: {
        'email': _emailCtrl.text.trim(), 'password': _passCtrl.text, 'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(), 'branch_id': int.parse(_selectedBranchId!),
      });
      if (!mounted) return;
      final token = res.data?['token'];
      final user = res.data?['user'];
      if (token != null && user != null) {
        // Auto-login and wait on the pending screen until the coach decides
        final authUser = {
          ...Map<String, dynamic>.from(user),
          'isLoggedIn': true,
          'isApproved': false,
          'token': token,
        };
        await context.read<AuthProvider>().login(authUser);
        if (mounted) context.go('/pending');
      } else {
        // Fallback for an older backend that doesn't return a token
        for (var c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) {
          c.clear();
        }
        setState(() => _selectedBranchId = null);
        await _showSuccessDialog(l);
        if (mounted) AppFeedback.showSuccess(context, l.translate('registration_submitted'));
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('server_error'));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _showSuccessDialog(AppLocalizations l) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        decoration: const BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 20),
          Text(l.translate('successfully_registered'), style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(l.translate('registration_submitted'), style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: PrimaryButton(label: l.translate('ok'), onPressed: () => Navigator.of(ctx).pop())),
        ]),
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
              label: l.translate('phone_optional'), controller: _phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined)),
            FadeSlideIn(delay: 320, child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, end: 4, bottom: AppSpacing.md),
              child: Text(l.translate('phone_verify_hint'), style: AppTypography.caption),
            )),
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
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(delay: 520, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: l.translate('agree_terms_prefix'), style: AppTypography.caption),
                  WidgetSpan(child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse('${ApiService.baseUrl}/terms-of-service'), mode: LaunchMode.externalApplication),
                    child: Text(l.translate('terms_of_service'), style: AppTypography.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  )),
                  TextSpan(text: l.translate('and_word'), style: AppTypography.caption),
                  WidgetSpan(child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse('${ApiService.baseUrl}/privacy-policy'), mode: LaunchMode.externalApplication),
                    child: Text(l.translate('privacy_policy'), style: AppTypography.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  )),
                ]),
                textAlign: TextAlign.center,
              ),
            )),
            const SizedBox(height: AppSpacing.lg),
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
