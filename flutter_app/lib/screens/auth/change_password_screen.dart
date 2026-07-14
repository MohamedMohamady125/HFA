import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _handleChange() async {
    final l = AppLocalizations.of(context);
    if (_currentCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      AppFeedback.showError(context, Exception(), fallback: l.translate('fill_all_fields'));
      return;
    }
    if (!ConnectivityService.isOnline) {
      AppFeedback.showError(context, Exception(),
          fallback: l.translate('offline_change_password'));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/change-password', data: {'old_password': _currentCtrl.text, 'new_password': _newCtrl.text});
      if (!mounted) return;
      AppFeedback.showSuccess(context, l.translate('password_changed'));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, e, fallback: l.translate('password_failed'));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            const FadeSlideIn(child: IconBadge(icon: Icons.lock_reset_rounded, color: AppColors.accent, size: 64, radius: 20)),
            const SizedBox(height: AppSpacing.xxl),
            FadeSlideIn(delay: 60, child: Text(l.translate('change_password'), style: AppTypography.displayLarge)),
            const SizedBox(height: AppSpacing.xxxl),
            FadeSlideIn(delay: 120, child: AppFormField(
              label: l.translate('current_password'),
              controller: _currentCtrl,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
            )),
            FadeSlideIn(delay: 180, child: AppFormField(
              label: l.translate('new_password'),
              controller: _newCtrl,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
            )),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(delay: 240, child: PrimaryButton(
              label: l.translate('update_password'),
              loading: _loading,
              onPressed: _handleChange,
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
  void dispose() { _currentCtrl.dispose(); _newCtrl.dispose(); super.dispose(); }
}
